//+------------------------------------------------------------------+
//|                                           C_VisualRenderer.mqh   |
//|                             Lula Price Action Execution Engine V3|
//+------------------------------------------------------------------+
#ifndef C_VISUALRENDERER_MQH
#define C_VISUALRENDERER_MQH

#include "../Sprint1_Sensors/CZigZagEngine.mqh"
#include "../Sprint1_Sensors/C_POI_Sensor.mqh"
#include "../Sprint1_Sensors/C_MarketStructureSensor.mqh"

class C_VisualRenderer {
public:
    static void DrawZigZag(CZigZagEngine *zz, string prefix, color clr, int width) {
        if(zz == NULL) return;
        SZZNode nodes[];
        int count = zz.GetNodes(50, nodes);
        for(int i = 0; i < count - 1; i++) {
            if(nodes[i].time == 0 || nodes[i+1].time == 0) continue;
            string name = prefix + "_ZZ_" + IntegerToString(i);
            if(ObjectFind(0, name) < 0) {
                ObjectCreate(0, name, OBJ_TREND, 0, nodes[i].time, nodes[i].price, nodes[i+1].time, nodes[i+1].price);
            }
            else { 
                ObjectSetInteger(0, name, OBJPROP_TIME, 0, nodes[i].time); 
                ObjectSetDouble(0, name, OBJPROP_PRICE, 0, nodes[i].price);
                ObjectSetInteger(0, name, OBJPROP_TIME, 1, nodes[i+1].time); 
                ObjectSetDouble(0, name, OBJPROP_PRICE, 1, nodes[i+1].price); 
            }
            ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
            ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
            ObjectSetInteger(0, name, OBJPROP_BACK, true);
        }
    }

    static void DrawPDRange(C_MarketStructureSensor *htf) {
        if(htf == NULL) return;
        double sl = htf.GetLastStrongLow(), wh = htf.GetLastWeakHigh();
        if(sl > 0 && wh > 0) {
            double eq = sl + ((wh - sl) / 2.0);
            string name = "HTF_Equilibrium_50";
            if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_HLINE, 0, 0, eq);
            else ObjectSetDouble(0, name, OBJPROP_PRICE, 0, eq);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrYellow);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
        }
    }

    static void DrawPOI(C_POI_Sensor *poiSensor) {
        if(poiSensor == NULL) return;
        int count = poiSensor.GetPOICount();
        for(int i = 0; i < count; i++) {
            SPOI poi = poiSensor.GetPOI(i);
            string name = "POI_" + IntegerToString(poi.time);
            if(!poi.isActive) { ObjectDelete(0, name); continue; }
            if(ObjectFind(0, name) < 0) {
                ObjectCreate(0, name, OBJ_RECTANGLE, 0, poi.time, poi.top, TimeCurrent() + PeriodSeconds(PERIOD_H1)*20, poi.bottom);
                ObjectSetInteger(0, name, OBJPROP_COLOR, poi.isBullish ? clrDarkGreen : clrDarkRed);
                ObjectSetInteger(0, name, OBJPROP_FILL, true);
                ObjectSetInteger(0, name, OBJPROP_BACK, true);
            } else {
                ObjectSetInteger(0, name, OBJPROP_TIME, 1, TimeCurrent() + PeriodSeconds(PERIOD_H1)*20);
            }
        }
    }

    static void DrawOrderBlocks(C_POI_Sensor *poiSensor) {
        DrawPOI(poiSensor);
    }

    static void Clear(string prefix = "") {
        ObjectsDeleteAll(0, prefix);
    }
};
#endif
