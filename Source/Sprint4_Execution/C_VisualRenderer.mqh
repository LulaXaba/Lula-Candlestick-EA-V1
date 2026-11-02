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

class C_VisualRenderer {
public:
    static void RenderAll(CZigZagEngine *htfZZ, CZigZagEngine *mtfZZ,
                          C_MarketStructureSensor *htfStruct, C_POI_Sensor *poiSensor,
                          string tradeSymbol = "", ulong tradeMagic = 0) {
        long chart_id = ChartFirst();
        while(chart_id >= 0) {
            DrawZigZag(chart_id, htfZZ, "HTF", clrDodgerBlue, 3);
            DrawZigZag(chart_id, mtfZZ, "MTF", clrDarkOrange, 1);
            DrawPDRange(chart_id, htfStruct);
            DrawPOIs(chart_id, poiSensor);
            DrawTrades(chart_id, tradeSymbol, tradeMagic);   // [PATCH VIZ-3]
            ChartRedraw(chart_id);
            chart_id = ChartNext(chart_id);
        }
    }

    static void DrawZigZag(long chart_id, CZigZagEngine *zz, string prefix, color clr, int width) {
        if(zz == NULL) return;
        SZZNode nodes[];
        int count = zz.GetNodes(50, nodes);
        for(int i = 0; i < count - 1; i++) {
            if(nodes[i].time == 0 || nodes[i+1].time == 0) continue;
            string name = prefix + "_ZZ_" + IntegerToString(i);
            if(ObjectFind(chart_id, name) < 0) {
                ObjectCreate(chart_id, name, OBJ_TREND, 0, nodes[i].time, nodes[i].price, nodes[i+1].time, nodes[i+1].price);
                ObjectSetInteger(chart_id, name, OBJPROP_COLOR, clr);
                ObjectSetInteger(chart_id, name, OBJPROP_WIDTH, width);
                ObjectSetInteger(chart_id, name, OBJPROP_RAY_RIGHT, false);
                ObjectSetInteger(chart_id, name, OBJPROP_BACK, false);
                ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN, true); // Hide from list to reduce lag
            } else { 
                ObjectSetInteger(chart_id, name, OBJPROP_TIME, 0, nodes[i].time); 
                ObjectSetDouble(chart_id, name, OBJPROP_PRICE, 0, nodes[i].price);
                ObjectSetInteger(chart_id, name, OBJPROP_TIME, 1, nodes[i+1].time); 
                ObjectSetDouble(chart_id, name, OBJPROP_PRICE, 1, nodes[i+1].price); 
            }
        }
    }

    static void DrawPDRange(long chart_id, C_MarketStructureSensor *htf) {
        if(htf == NULL) return;
        
        double discount_thresh = htf.GetDiscountThreshold();
        if(discount_thresh > 0) {
            string name = "HTF_Discount_Threshold";
            if(ObjectFind(chart_id, name) < 0) {
                ObjectCreate(chart_id, name, OBJ_HLINE, 0, 0, discount_thresh);
                ObjectSetInteger(chart_id, name, OBJPROP_COLOR, clrLimeGreen);
                ObjectSetInteger(chart_id, name, OBJPROP_STYLE, STYLE_DASH);
                ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN, true);
            } else ObjectSetDouble(chart_id, name, OBJPROP_PRICE, 0, discount_thresh);
        }

        double premium_thresh = htf.GetPremiumThreshold();
        if(premium_thresh > 0) {
            string name = "HTF_Premium_Threshold";
            if(ObjectFind(chart_id, name) < 0) {
                ObjectCreate(chart_id, name, OBJ_HLINE, 0, 0, premium_thresh);
                ObjectSetInteger(chart_id, name, OBJPROP_COLOR, clrDeepPink);
                ObjectSetInteger(chart_id, name, OBJPROP_STYLE, STYLE_DASH);
                ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN, true);
            } else ObjectSetDouble(chart_id, name, OBJPROP_PRICE, 0, premium_thresh);
        }
    }

    static void DrawPOIs(long chart_id, C_POI_Sensor *poiSensor) {
        if(poiSensor == NULL) return;
        int count = poiSensor.GetPOICount();
        for(int i = 0; i < count; i++) {
            SPOI poi = poiSensor.GetPOI(i);
            string name = "POI_" + IntegerToString((int)poi.time);
            if(!poi.isActive) { ObjectDelete(chart_id, name); continue; }
            if(ObjectFind(chart_id, name) < 0) {
                ObjectCreate(chart_id, name, OBJ_RECTANGLE, 0, poi.time, poi.top, TimeCurrent() + PeriodSeconds(PERIOD_H1)*20, poi.bottom);
                ObjectSetInteger(chart_id, name, OBJPROP_COLOR, poi.isBullish ? clrDarkGreen : clrDarkRed);
                ObjectSetInteger(chart_id, name, OBJPROP_FILL, true);
                ObjectSetInteger(chart_id, name, OBJPROP_BACK, true);
                ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN, true);
            } else {
                ObjectSetInteger(chart_id, name, OBJPROP_TIME, 1, TimeCurrent() + PeriodSeconds(PERIOD_H1)*20);
            }
        }
    }

    // [PATCH VIZ-1] Draw every open ticket for this symbol+magic.
    // Colors: entry = blue/orange (long/short), SL = red dotted, TP = lime dashed.
    // Tier is extracted from the " T1"/" T2"/" T3" comment suffix.
    static void DrawTrades(long chart_id, string symbol, ulong magic)
    {
        if(symbol == "" || magic == 0) return;

        // --- Draw current positions ---
        ulong liveTickets[];
        ArrayResize(liveTickets, 0);

        int total = PositionsTotal();
        for(int i = 0; i < total; i++)
        {
            ulong tk = PositionGetTicket(i);
            if(tk == 0) continue;
            if(PositionGetString(POSITION_SYMBOL)             != symbol) continue;
            if((ulong)PositionGetInteger(POSITION_MAGIC)      != magic)  continue;

            int n = ArraySize(liveTickets);
            ArrayResize(liveTickets, n + 1);
            liveTickets[n] = tk;

            string comment = PositionGetString(POSITION_COMMENT);
            string tier    = "TX";
            if(StringFind(comment, " T1") >= 0)      tier = "T1";
            else if(StringFind(comment, " T2") >= 0) tier = "T2";
            else if(StringFind(comment, " T3") >= 0) tier = "T3";

            bool   isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
            double entry = PositionGetDouble(POSITION_PRICE_OPEN);
            double sl    = PositionGetDouble(POSITION_SL);
            double tp    = PositionGetDouble(POSITION_TP);

            string base = "TRADE_" + IntegerToString((int)tk) + "_" + tier;

            _HLine(chart_id, base + "_E",  entry,
                   isBuy ? clrDodgerBlue : clrOrange, STYLE_SOLID, 1);
            if(sl > 0.0)
                _HLine(chart_id, base + "_SL", sl, clrRed,       STYLE_DOT,  2);
            if(tp > 0.0)
                _HLine(chart_id, base + "_TP", tp, clrLimeGreen, STYLE_DASH, 2);
        }

        // --- Purge stale TRADE_ objects whose ticket is no longer open ---
        int objTotal = ObjectsTotal(chart_id, 0, -1);
        for(int i = objTotal - 1; i >= 0; i--)
        {
            string name = ObjectName(chart_id, i, 0, -1);
            if(StringFind(name, "TRADE_") != 0) continue;

            // name = "TRADE_<ticket>_<tier>_<kind>"; ticket starts at index 6
            string after  = StringSubstr(name, 6);
            int    uscore = StringFind(after, "_");
            if(uscore <= 0) { ObjectDelete(chart_id, name); continue; }

            ulong tk = (ulong)StringToInteger(StringSubstr(after, 0, uscore));
            bool  alive = false;
            for(int j = 0; j < ArraySize(liveTickets); j++)
                if(liveTickets[j] == tk) { alive = true; break; }
            if(!alive) ObjectDelete(chart_id, name);
        }
    }

    // [PATCH VIZ-2] Small helper — create-or-update a horizontal line.
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

    static void Clear(string prefix = "") {
        long chart_id = ChartFirst();
        while(chart_id >= 0) {
            ObjectsDeleteAll(chart_id, prefix);
            chart_id = ChartNext(chart_id);
        }
    }
};
#endif
