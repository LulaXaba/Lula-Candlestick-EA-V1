//+------------------------------------------------------------------+
//|                                              C_TradeManager.mqh  |
//|                       Per-position profit securing & dynamic SL  |
//+------------------------------------------------------------------+
#ifndef C_TRADEMANAGER_MQH
#define C_TRADEMANAGER_MQH

#include "../Sprint1_Sensors/C_MarketStructureSensor.mqh"
#include "../Sprint1_Sensors/CZigZagEngine.mqh"

struct STrackedTicket
{
    ulong    positionId;
    int      tier;            // 1 = T1, 2 = T2, 3 = T3
    long     direction;       // +1 long, -1 short
    double   entryPrice;
    double   initialSL;
    double   currentSL;
    double   tp;
    bool     isOpen;
};

struct STradeGroup
{
    ulong          groupId;
    long           direction;
    double         entryPrice;
    datetime       entryTime;
    int            trendAtEntry;
    double         atrAtEntry;
    bool           t1Hit;
    bool           t2Hit;
    string         modelName;
    STrackedTicket tickets[3];
};

class C_TradeManager
{
private:
    string          m_symbol;
    ulong           m_magic;
    ENUM_TIMEFRAMES m_ltf;
    STradeGroup     m_groups[];
    double          m_mitigBufATR;      // SL buffer around swing, as ATR fraction
    double          m_earlyProtectATR;  // "T0" — move to BE once this much profit
    bool            m_enableEarlyProtect;

    // --- swing helpers (see below) ---
    double  FindLastSwingLow (CZigZagEngine* zz);
    double  FindLastSwingHigh(CZigZagEngine* zz);
    double  FindNewestHL     (CZigZagEngine* zz, double currentSL, double price);
    double  FindNewestLH     (CZigZagEngine* zz, double currentSL, double price);

    // --- order plumbing ---
    bool    IsPositionOpen(ulong posId);
    bool    BetterSL(long dir, double candidate, double current);
    bool    MoveStop(ulong posId, double newSL);
    bool    CloseTicket(ulong posId, string reason);
    void    Prune();

public:
                    C_TradeManager();
                   ~C_TradeManager() {}

    bool            Init(string symbol, ulong magic, ENUM_TIMEFRAMES ltf,
                         double mitigBufATR     = 0.25,
                         double earlyProtectATR = 1.00,
                         bool   enableEarly     = true);

    void            Register(ulong positionId, int tier, long direction,
                             double entryPrice, double initialSL, double tp,
                             int trendAtEntry, double atrAtEntry,
                             string modelName, datetime groupEntryTime);

    // Called once per new LTF bar, after state machine routing
    void            OnLtfBar(C_MarketStructureSensor* htf_structure,
                             C_MarketStructureSensor* ltf_structure,
                             CZigZagEngine* ltf_zigzag);

    int             OpenGroupCount();
    void            CloseAll(string reason);
};

//====================================================================
// Construction / init
//====================================================================
C_TradeManager::C_TradeManager()
    : m_symbol(""), m_magic(0), m_ltf(PERIOD_M5),
      m_mitigBufATR(0.25), m_earlyProtectATR(1.00), m_enableEarlyProtect(true)
{ ArrayResize(m_groups, 0); }

bool C_TradeManager::Init(string symbol, ulong magic, ENUM_TIMEFRAMES ltf,
                          double mitigBufATR, double earlyProtectATR, bool enableEarly)
{
    m_symbol           = symbol;
    m_magic            = magic;
    m_ltf              = ltf;
    m_mitigBufATR      = mitigBufATR;
    m_earlyProtectATR  = earlyProtectATR;
    m_enableEarlyProtect = enableEarly;
    ArrayResize(m_groups, 0);
    PrintFormat("[V3 TradeManager] Init %s | Magic=%I64u | MitigBuf=%.2f ATR | EarlyProtect=%s@%.2f ATR",
                m_symbol, m_magic, m_mitigBufATR,
                m_enableEarlyProtect ? "ON" : "OFF", m_earlyProtectATR);
    return true;
}

//====================================================================
// Register a newly-filled ticket
//====================================================================
void C_TradeManager::Register(ulong positionId, int tier, long direction,
                              double entryPrice, double initialSL, double tp,
                              int trendAtEntry, double atrAtEntry,
                              string modelName, datetime groupEntryTime)
{
    if(positionId == 0) return;

    // Find or create the group for this entry time
    int gi = -1;
    for(int i = 0; i < ArraySize(m_groups); i++)
        if(m_groups[i].entryTime == groupEntryTime && m_groups[i].direction == direction)
        { gi = i; break; }

    if(gi < 0)
    {
        gi = ArraySize(m_groups);
        ArrayResize(m_groups, gi + 1);
        m_groups[gi].groupId      = (ulong)groupEntryTime;
        m_groups[gi].direction    = direction;
        m_groups[gi].entryPrice   = entryPrice;
        m_groups[gi].entryTime    = groupEntryTime;
        m_groups[gi].trendAtEntry = trendAtEntry;
        m_groups[gi].atrAtEntry   = atrAtEntry;
        m_groups[gi].t1Hit        = false;
        m_groups[gi].t2Hit        = false;
        m_groups[gi].modelName    = modelName;
        for(int t = 0; t < 3; t++)
        {
            m_groups[gi].tickets[t].positionId = 0;
            m_groups[gi].tickets[t].isOpen     = false;
        }
    }

    int ti = tier - 1;
    if(ti < 0 || ti > 2) return;
    m_groups[gi].tickets[ti].positionId = positionId;
    m_groups[gi].tickets[ti].tier       = tier;
    m_groups[gi].tickets[ti].direction  = direction;
    m_groups[gi].tickets[ti].entryPrice = entryPrice;
    m_groups[gi].tickets[ti].initialSL  = initialSL;
    m_groups[gi].tickets[ti].currentSL  = initialSL;
    m_groups[gi].tickets[ti].tp         = tp;
    m_groups[gi].tickets[ti].isOpen     = true;

    PrintFormat("[V3 TradeManager] Registered T%d #%I64u dir=%s entry=%.5f sl=%.5f tp=%.5f [%s]",
                tier, positionId, direction > 0 ? "LONG" : "SHORT",
                entryPrice, initialSL, tp, modelName);
}

//====================================================================
// Main loop — called once per new LTF bar
//====================================================================
void C_TradeManager::OnLtfBar(C_MarketStructureSensor* htf_structure,
                              C_MarketStructureSensor* ltf_structure,
                              CZigZagEngine* ltf_zigzag)
{
    if(htf_structure == NULL || ltf_structure == NULL || ltf_zigzag == NULL) return;

    double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
    if(bid <= 0.0 || ask <= 0.0) return;

    int    currentTrend  = htf_structure.GetTrendDirection();
    double lastSwingLow  = FindLastSwingLow(ltf_zigzag);
    double lastSwingHigh = FindLastSwingHigh(ltf_zigzag);
    double c1            = iClose(m_symbol, m_ltf, 1);
    if(c1 <= 0.0) return;

    for(int g = 0; g < ArraySize(m_groups); g++)
    {
        if(m_groups[g].direction == 0) continue;

        //----------------------------------------------------------
        // 1. TREND FLIP EXIT (highest priority)
        //----------------------------------------------------------
        bool trendFlipped = (m_groups[g].direction == +1 && currentTrend == -1) ||
                            (m_groups[g].direction == -1 && currentTrend == +1);

        bool structureFlipped = false;
        if(m_groups[g].direction == +1 && lastSwingLow  > 0 && c1 < lastSwingLow ) structureFlipped = true;
        if(m_groups[g].direction == -1 && lastSwingHigh > 0 && c1 > lastSwingHigh) structureFlipped = true;

        if(trendFlipped || structureFlipped)
        {
            string reason = trendFlipped ? "HTF trend flipped" : "LTF CHoCH break";
            PrintFormat("[V3 Manage] Group %I64u EXIT — %s (was %s, now trend=%d, close=%.5f)",
                        m_groups[g].groupId, reason, m_groups[g].direction > 0 ? "LONG" : "SHORT",
                        currentTrend, c1);
            for(int t = 0; t < 3; t++)
                if(m_groups[g].tickets[t].isOpen)
                {
                    CloseTicket(m_groups[g].tickets[t].positionId, reason);
                    m_groups[g].tickets[t].isOpen = false;
                }
            m_groups[g].direction = 0;
            continue;
        }

        //----------------------------------------------------------
        // 2. DETECT T1 / T2 HITS (broker TP closed ticket → flag it)
        //----------------------------------------------------------
        if(!m_groups[g].t1Hit && m_groups[g].tickets[0].isOpen && !IsPositionOpen(m_groups[g].tickets[0].positionId))
        {
            m_groups[g].t1Hit = true;
            m_groups[g].tickets[0].isOpen = false;
            PrintFormat("[V3 Manage] Group %I64u — T1 HIT (%.5f). SL of T2/T3 → breakeven %.5f",
                        m_groups[g].groupId, m_groups[g].tickets[0].tp, m_groups[g].entryPrice);
            for(int t = 1; t < 3; t++)
                if(m_groups[g].tickets[t].isOpen && BetterSL(m_groups[g].direction, m_groups[g].entryPrice, m_groups[g].tickets[t].currentSL))
                {
                    if(MoveStop(m_groups[g].tickets[t].positionId, m_groups[g].entryPrice))
                        m_groups[g].tickets[t].currentSL = m_groups[g].entryPrice;
                }
        }
        if(!m_groups[g].t2Hit && m_groups[g].tickets[1].isOpen && !IsPositionOpen(m_groups[g].tickets[1].positionId))
        {
            m_groups[g].t2Hit = true;
            m_groups[g].tickets[1].isOpen = false;
            PrintFormat("[V3 Manage] Group %I64u — T2 HIT (%.5f). Trailing T3 to swing HL/LH.",
                        m_groups[g].groupId, m_groups[g].tickets[1].tp);
        }

        //----------------------------------------------------------
        // 3. DYNAMIC SL (per open ticket)
        //----------------------------------------------------------
        for(int t = 0; t < 3; t++)
        {
            if(!m_groups[g].tickets[t].isOpen) continue;

            double price = (m_groups[g].direction == +1) ? bid : ask;
            double newSL = m_groups[g].tickets[t].currentSL;

            // T0 — early profit protection before T1
            if(m_enableEarlyProtect && !m_groups[g].t1Hit)
            {
                double profit = (m_groups[g].direction == +1) ? (bid - m_groups[g].entryPrice)
                                                              : (m_groups[g].entryPrice - ask);
                if(profit > m_groups[g].atrAtEntry * m_earlyProtectATR)
                {
                    double prot = (m_groups[g].direction == +1)
                                  ? m_groups[g].entryPrice + m_groups[g].atrAtEntry * 0.05
                                  : m_groups[g].entryPrice - m_groups[g].atrAtEntry * 0.05;
                    if(BetterSL(m_groups[g].direction, prot, newSL)) newSL = prot;
                }
            }

            // After T2 → trail to most recent HL (long) / LH (short)
            if(m_groups[g].t2Hit)
            {
                double buffer = m_groups[g].atrAtEntry * m_mitigBufATR;
                if(m_groups[g].direction == +1)
                {
                    double hl = FindNewestHL(ltf_zigzag, newSL, price);
                    if(hl > 0.0 && (hl - buffer) > newSL) newSL = hl - buffer;
                }
                else
                {
                    double lh = FindNewestLH(ltf_zigzag, newSL, price);
                    if(lh > 0.0 && (lh + buffer) < newSL) newSL = lh + buffer;
                }
            }

            if(newSL != m_groups[g].tickets[t].currentSL && BetterSL(m_groups[g].direction, newSL, m_groups[g].tickets[t].currentSL))
            {
                if(MoveStop(m_groups[g].tickets[t].positionId, newSL))
                {
                    PrintFormat("[V3 Manage] Group %I64u T%d SL → %.5f (was %.5f)",
                                m_groups[g].groupId, t + 1, newSL, m_groups[g].tickets[t].currentSL);
                    m_groups[g].tickets[t].currentSL = newSL;
                }
            }
        }
    }

    Prune();
}

//====================================================================
// Swing helpers
//====================================================================
double C_TradeManager::FindLastSwingLow(CZigZagEngine* zz)
{
    for(int i = 0; i < zz.GetNodeCount(); i++)
        if(!zz.IsNodeHigh(i)) return zz.GetNodePrice(i);
    return 0.0;
}
double C_TradeManager::FindLastSwingHigh(CZigZagEngine* zz)
{
    for(int i = 0; i < zz.GetNodeCount(); i++)
        if( zz.IsNodeHigh(i)) return zz.GetNodePrice(i);
    return 0.0;
}

// Returns the NEWEST swing low that is higher than its predecessor (an HL),
// and also between currentSL and price (a valid tightening).
double C_TradeManager::FindNewestHL(CZigZagEngine* zz, double currentSL, double price)
{
    double prevLow = 0.0;                 // newer low
    for(int i = 0; i < zz.GetNodeCount(); i++)
    {
        if(zz.IsNodeHigh(i)) continue;
        double low = zz.GetNodePrice(i);  // this is the OLDER low
        if(prevLow == 0.0) { prevLow = low; continue; }
        // prevLow is newer, low is older → HL if prevLow > low
        if(prevLow > low && prevLow > currentSL && prevLow < price)
            return prevLow;               // first match walking back = newest HL
        prevLow = low;
    }
    return 0.0;
}

// Mirror for short: newest high lower than its predecessor (an LH).
double C_TradeManager::FindNewestLH(CZigZagEngine* zz, double currentSL, double price)
{
    double prevHigh = 0.0;
    for(int i = 0; i < zz.GetNodeCount(); i++)
    {
        if(!zz.IsNodeHigh(i)) continue;
        double high = zz.GetNodePrice(i);
        if(prevHigh == 0.0) { prevHigh = high; continue; }
        if(prevHigh < high && prevHigh < currentSL && prevHigh > price)
            return prevHigh;
        prevHigh = high;
    }
    return 0.0;
}

//====================================================================
// Order plumbing
//====================================================================
bool C_TradeManager::IsPositionOpen(ulong posId)
{
    if(posId == 0) return false;
    if(!PositionSelectByTicket(posId)) return false;
    return ((ulong)PositionGetInteger(POSITION_MAGIC) == m_magic);
}

bool C_TradeManager::BetterSL(long dir, double candidate, double current)
{
    if(dir == +1) return candidate > current;   // long: SL higher is better
    if(dir == -1) return candidate < current;   // short: SL lower is better
    return false;
}

bool C_TradeManager::MoveStop(ulong posId, double newSL)
{
    if(!PositionSelectByTicket(posId)) return false;

    long   type       = PositionGetInteger(POSITION_TYPE);
    double tp         = PositionGetDouble(POSITION_TP);
    double bid        = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    double ask        = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
    long   stopsLevel = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double point      = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    double minDist    = stopsLevel * (point > 0.0 ? point : _Point);
    int    digits     = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
    double nSL        = NormalizeDouble(newSL, digits);

    if(type == POSITION_TYPE_BUY  && (bid - nSL) < minDist) return false;
    if(type == POSITION_TYPE_SELL && (nSL - ask) < minDist) return false;

    MqlTradeRequest req = {};
    MqlTradeResult  res = {};
    req.action   = TRADE_ACTION_SLTP;
    req.position = posId;
    req.symbol   = m_symbol;
    req.sl       = nSL;
    req.tp       = tp;

    if(!OrderSend(req, res) || res.retcode != TRADE_RETCODE_DONE)
    {
        PrintFormat("[V3 TradeManager] SL modify FAILED #%I64u → %.5f (rc=%d %s)",
                    posId, nSL, res.retcode, res.comment);
        return false;
    }
    return true;
}

bool C_TradeManager::CloseTicket(ulong posId, string reason)
{
    if(!PositionSelectByTicket(posId)) return false;

    MqlTradeRequest req = {};
    MqlTradeResult  res = {};
    req.action   = TRADE_ACTION_DEAL;
    req.position = posId;
    req.symbol   = m_symbol;
    req.volume   = PositionGetDouble(POSITION_VOLUME);
    req.deviation= 20;
    req.magic    = m_magic;

    long type = PositionGetInteger(POSITION_TYPE);
    if(type == POSITION_TYPE_BUY)
    {
        req.type  = ORDER_TYPE_SELL;
        req.price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    }
    else
    {
        req.type  = ORDER_TYPE_BUY;
        req.price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
    }

    if(!OrderSend(req, res) || res.retcode != TRADE_RETCODE_DONE)
    {
        PrintFormat("[V3 TradeManager] CLOSE FAILED #%I64u (%s) rc=%d", posId, reason, res.retcode);
        return false;
    }
    PrintFormat("[V3 TradeManager] CLOSED #%I64u — %s", posId, reason);
    return true;
}

void C_TradeManager::Prune()
{
    for(int i = ArraySize(m_groups) - 1; i >= 0; i--)
    {
        bool anyOpen = false;
        for(int t = 0; t < 3; t++)
            if(m_groups[i].tickets[t].isOpen && IsPositionOpen(m_groups[i].tickets[t].positionId))
                { anyOpen = true; break; }
        if(!anyOpen)
        {
            for(int k = i; k < ArraySize(m_groups) - 1; k++)
                m_groups[k] = m_groups[k + 1];
            ArrayResize(m_groups, ArraySize(m_groups) - 1);
        }
    }
}

int C_TradeManager::OpenGroupCount()
{
    int n = 0;
    for(int i = 0; i < ArraySize(m_groups); i++)
        for(int t = 0; t < 3; t++)
            if(m_groups[i].tickets[t].isOpen) { n++; break; }
    return n;
}

void C_TradeManager::CloseAll(string reason)
{
    for(int i = 0; i < ArraySize(m_groups); i++)
    {
        for(int t = 0; t < 3; t++)
            if(m_groups[i].tickets[t].isOpen)
            {
                CloseTicket(m_groups[i].tickets[t].positionId, reason);
                m_groups[i].tickets[t].isOpen = false;
            }
        m_groups[i].direction = 0;
    }
    Prune();
}

#endif
