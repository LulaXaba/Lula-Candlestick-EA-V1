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
    static void RenderAll(CZigZagEngine *htfZZ, CZigZagEngine *mtfZZ, C_MarketStructureSensor *htfStruct, C_POI_Sensor *poiSensor) {
        long chart_id = ChartFirst();
        while(chart_id >= 0) {
            DrawZigZag(chart_id, htfZZ, "HTF", clrDodgerBlue, 3);
            DrawZigZag(chart_id, mtfZZ, "MTF", clrDarkOrange, 1);
            DrawPDRange(chart_id, htfStruct);
            DrawPOIs(chart_id, poiSensor);
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

    static void Clear(string prefix = "") {
        long chart_id = ChartFirst();
        while(chart_id >= 0) {
            ObjectsDeleteAll(chart_id, prefix);
            chart_id = ChartNext(chart_id);
        }
    }
};
#endif
