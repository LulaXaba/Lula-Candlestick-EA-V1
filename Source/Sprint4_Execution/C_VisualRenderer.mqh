//+------------------------------------------------------------------+
//|                                           C_VisualRenderer.mqh   |
//|                             Lula Price Action Execution Engine V3|
//|               Multi-Chart Synchronized Institutional Renderer    |
//+------------------------------------------------------------------+
#ifndef C_VISUALRENDERER_MQH
#define C_VISUALRENDERER_MQH

#include "../Sprint1_Sensors/CZigZagEngine.mqh"
#include "../Sprint1_Sensors/C_POI_Sensor.mqh"
#include "../Sprint1_Sensors/C_MarketStructureSensor.mqh"

// [FIX 4] Render scope — perf knob
enum ENUM_VIS_RENDER_TARGET
{
    VIS_RENDER_CURRENT,          // current chart only (default — fast)
    VIS_RENDER_ALL_SAME_SYMBOL,  // every chart on the same symbol
    VIS_RENDER_ALL               // every chart on the terminal
};

class C_VisualRenderer
{
private:
    // Create-or-update a horizontal line
    static void _HLine(long chart_id, string name, double price,
                       color clr, ENUM_LINE_STYLE style, int width)
    {
        if(ObjectFind(chart_id, name) < 0)
        {
            ObjectCreate(chart_id, name, OBJ_HLINE, 0, 0, price);
            ObjectSetInteger(chart_id, name, OBJPROP_COLOR,  clr);
            ObjectSetInteger(chart_id, name, OBJPROP_STYLE,  style);
            ObjectSetInteger(chart_id, name, OBJPROP_WIDTH,  width);
            ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN, true);
        }
        else
            ObjectSetDouble(chart_id, name, OBJPROP_PRICE, 0, price);
    }

    // [FIX 2] Delete zigzag segments whose index exceeds the current node count.
    // Objects are named <prefix>_ZZ_<i>. Anything with i >= count-1 is stale.
    static void _PruneZigZag(long chart_id, string prefix, int currentCount)
    {
        string pfx     = prefix + "_ZZ_";
        int    pfxLen  = StringLen(pfx);
        int    total   = ObjectsTotal(chart_id, 0, -1);
        for(int i = total - 1; i >= 0; i--)
        {
            string name = ObjectName(chart_id, i, 0, -1);
            if(StringFind(name, pfx) != 0) continue;
            string tail = StringSubstr(name, pfxLen);
            int    idx  = (int)StringToInteger(tail);
            if(idx >= currentCount - 1)
                ObjectDelete(chart_id, name);
        }
    }

    // Single-chart renderer
    static void _RenderOne(long chart_id,
                           CZigZagEngine *htfZZ, CZigZagEngine *mtfZZ,
                           C_MarketStructureSensor *htfStruct, C_POI_Sensor *poiSensor,
                           string tradeSymbol, ulong tradeMagic,
                           datetime rightEdge, bool showInactivePOIs)
    {
        DrawZigZag(chart_id, htfZZ, "HTF", clrDodgerBlue, 3);
        DrawZigZag(chart_id, mtfZZ, "MTF", clrDarkOrange, 1);
        DrawPDRange(chart_id, htfStruct);
        DrawPOIs  (chart_id, poiSensor, rightEdge, showInactivePOIs);
        DrawTrades(chart_id, tradeSymbol, tradeMagic);
        ChartRedraw(chart_id);
    }

public:
    // [FIX 3+4] extendTF drives the right edge; target controls scope.
    // 4 mandatory args keeps old call sites compiling unchanged.
    static void RenderAll(CZigZagEngine *htfZZ, CZigZagEngine *mtfZZ,
                          C_MarketStructureSensor *htfStruct, C_POI_Sensor *poiSensor,
                          string tradeSymbol             = "",
                          ulong  tradeMagic              = 0,
                          ENUM_VIS_RENDER_TARGET target  = VIS_RENDER_CURRENT,
                          ENUM_TIMEFRAMES extendTF       = PERIOD_CURRENT,
                          bool  showInactivePOIs         = false)
    {
        int      extendSecs = PeriodSeconds(extendTF == PERIOD_CURRENT ? _Period : extendTF);
        datetime rightEdge  = TimeCurrent() + extendSecs * 20;

        if(target == VIS_RENDER_CURRENT)
        {
            _RenderOne(ChartID(), htfZZ, mtfZZ, htfStruct, poiSensor,
                       tradeSymbol, tradeMagic, rightEdge, showInactivePOIs);
            return;
        }

        long cid = ChartFirst();
        while(cid >= 0)
        {
            bool doRender = (target == VIS_RENDER_ALL) ||
                            (target == VIS_RENDER_ALL_SAME_SYMBOL && ChartSymbol(cid) == _Symbol);
            if(doRender)
                _RenderOne(cid, htfZZ, mtfZZ, htfStruct, poiSensor,
                           tradeSymbol, tradeMagic, rightEdge, showInactivePOIs);
            cid = ChartNext(cid);
        }
    }

    //--------------------------------------------------------------
    // ZigZag
    //--------------------------------------------------------------
    static void DrawZigZag(long chart_id, CZigZagEngine *zz, string prefix, color clr, int width)
    {
        if(zz == NULL) return;
        SZZNode nodes[];
        int count = zz.GetNodes(50, nodes);
        for(int i = 0; i < count - 1; i++)
        {
            if(nodes[i].time == 0 || nodes[i+1].time == 0) continue;
            string name = prefix + "_ZZ_" + IntegerToString(i);
            if(ObjectFind(chart_id, name) < 0)
            {
                ObjectCreate(chart_id, name, OBJ_TREND, 0,
                             nodes[i].time, nodes[i].price,
                             nodes[i+1].time, nodes[i+1].price);
                ObjectSetInteger(chart_id, name, OBJPROP_COLOR, clr);
                ObjectSetInteger(chart_id, name, OBJPROP_WIDTH, width);
                ObjectSetInteger(chart_id, name, OBJPROP_RAY_RIGHT, false);
                ObjectSetInteger(chart_id, name, OBJPROP_BACK, false);
                ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN, true);
            }
            else
            {
                ObjectSetInteger(chart_id, name, OBJPROP_TIME,  0, nodes[i].time);
                ObjectSetDouble (chart_id, name, OBJPROP_PRICE, 0, nodes[i].price);
                ObjectSetInteger(chart_id, name, OBJPROP_TIME,  1, nodes[i+1].time);
                ObjectSetDouble (chart_id, name, OBJPROP_PRICE, 1, nodes[i+1].price);
            }
        }
        _PruneZigZag(chart_id, prefix, count);   // [FIX 2]
    }

    //--------------------------------------------------------------
    // Premium / Discount thresholds
    //--------------------------------------------------------------
    static void DrawPDRange(long chart_id, C_MarketStructureSensor *htf)
    {
        if(htf == NULL) return;

        double discount_thresh = htf.GetDiscountThreshold();
        if(discount_thresh > 0)
        {
            string name = "HTF_Discount_Threshold";
            if(ObjectFind(chart_id, name) < 0)
            {
                ObjectCreate(chart_id, name, OBJ_HLINE, 0, 0, discount_thresh);
                ObjectSetInteger(chart_id, name, OBJPROP_COLOR, clrLimeGreen);
                ObjectSetInteger(chart_id, name, OBJPROP_STYLE, STYLE_DASH);
                ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN, true);
            }
            else ObjectSetDouble(chart_id, name, OBJPROP_PRICE, 0, discount_thresh);
        }

        double premium_thresh = htf.GetPremiumThreshold();
        if(premium_thresh > 0)
        {
            string name = "HTF_Premium_Threshold";
            if(ObjectFind(chart_id, name) < 0)
            {
                ObjectCreate(chart_id, name, OBJ_HLINE, 0, 0, premium_thresh);
                ObjectSetInteger(chart_id, name, OBJPROP_COLOR, clrDeepPink);
                ObjectSetInteger(chart_id, name, OBJPROP_STYLE, STYLE_DASH);
                ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN, true);
            }
            else ObjectSetDouble(chart_id, name, OBJPROP_PRICE, 0, premium_thresh);
        }
    }

    //--------------------------------------------------------------
    // POIs — [FIX 1] long cast; [FIX 3] rightEdge param;
    //        [FIX 5] showInactive greys mitigated zones
    //--------------------------------------------------------------
    static void DrawPOIs(long chart_id, C_POI_Sensor *poiSensor,
                         datetime rightEdge, bool showInactive = false)
    {
        if(poiSensor == NULL) return;
        int count = poiSensor.GetPOICount();
        for(int i = 0; i < count; i++)
        {
            SPOI poi = poiSensor.GetPOI(i);

            // [FIX 1] (long) preserves 64-bit datetime
            string name = "POI_" + IntegerToString((long)poi.time);

            if(!poi.isActive && !showInactive)
            {
                ObjectDelete(chart_id, name);
                continue;
            }

            color clr  = poi.isBullish ? clrDarkGreen : clrDarkRed;
            bool  fill = poi.isActive;
            if(!poi.isActive) { clr = clrGray; fill = false; }   // [FIX 5]

            if(ObjectFind(chart_id, name) < 0)
            {
                ObjectCreate(chart_id, name, OBJ_RECTANGLE, 0,
                             poi.time, poi.top, rightEdge, poi.bottom);
                ObjectSetInteger(chart_id, name, OBJPROP_COLOR,  clr);
                ObjectSetInteger(chart_id, name, OBJPROP_FILL,   fill);
                ObjectSetInteger(chart_id, name, OBJPROP_BACK,   true);
                ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN, true);
            }
            else
            {
                ObjectSetInteger(chart_id, name, OBJPROP_TIME,  1, rightEdge);
                ObjectSetInteger(chart_id, name, OBJPROP_COLOR, clr);
                ObjectSetInteger(chart_id, name, OBJPROP_FILL,  fill);
            }
        }
    }
    // Backward-compat overload — uses current chart TF for the extension
    static void DrawPOIs(long chart_id, C_POI_Sensor *poiSensor)
    {
        DrawPOIs(chart_id, poiSensor,
                 TimeCurrent() + PeriodSeconds(_Period) * 20, false);
    }

    //--------------------------------------------------------------
    // Trade overlay — one HL per Entry / SL / TP, per open ticket
    //--------------------------------------------------------------
    static void DrawTrades(long chart_id, string symbol, ulong magic)
    {
        if(symbol == "" || magic == 0) return;

        ulong live[];
        ArrayResize(live, 0);

        int total = PositionsTotal();
        for(int i = 0; i < total; i++)
        {
            ulong tk = PositionGetTicket(i);
            if(tk == 0) continue;
            if(PositionGetString(POSITION_SYMBOL)        != symbol) continue;
            if((ulong)PositionGetInteger(POSITION_MAGIC) != magic)  continue;

            int n = ArraySize(live);
            ArrayResize(live, n + 1);
            live[n] = tk;

            string comment = PositionGetString(POSITION_COMMENT);
            string tier    = "TX";
            if     (StringFind(comment, " T1") >= 0) tier = "T1";
            else if(StringFind(comment, " T2") >= 0) tier = "T2";
            else if(StringFind(comment, " T3") >= 0) tier = "T3";

            bool   isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
            double entry = PositionGetDouble(POSITION_PRICE_OPEN);
            double sl    = PositionGetDouble(POSITION_SL);
            double tp    = PositionGetDouble(POSITION_TP);

            string base = "TRADE_" + IntegerToString((long)tk) + "_" + tier;

            _HLine(chart_id, base + "_E",
                   entry, isBuy ? clrDodgerBlue : clrOrange, STYLE_SOLID, 1);
            if(sl > 0.0)
                _HLine(chart_id, base + "_SL", sl, clrRed,       STYLE_DOT,  2);
            if(tp > 0.0)
                _HLine(chart_id, base + "_TP", tp, clrLimeGreen, STYLE_DASH, 2);
        }

        // Purge overlay objects whose ticket is no longer open
        int objTotal = ObjectsTotal(chart_id, 0, -1);
        for(int i = objTotal - 1; i >= 0; i--)
        {
            string name = ObjectName(chart_id, i, 0, -1);
            if(StringFind(name, "TRADE_") != 0) continue;

            string after  = StringSubstr(name, 6);        // strip "TRADE_"
            int    uscore = StringFind(after, "_");
            if(uscore <= 0) { ObjectDelete(chart_id, name); continue; }

            ulong tk    = (ulong)StringToInteger(StringSubstr(after, 0, uscore));
            bool  alive = false;
            for(int j = 0; j < ArraySize(live); j++)
                if(live[j] == tk) { alive = true; break; }
            if(!alive) ObjectDelete(chart_id, name);
        }
    }

    //--------------------------------------------------------------
    // Cleanup
    //--------------------------------------------------------------
    static void Clear(string prefix = "")
    {
        long chart_id = ChartFirst();
        while(chart_id >= 0)
        {
            ObjectsDeleteAll(chart_id, prefix);
            chart_id = ChartNext(chart_id);
        }
    }
};
#endif
