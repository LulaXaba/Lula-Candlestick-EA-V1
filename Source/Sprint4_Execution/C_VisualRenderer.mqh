//+------------------------------------------------------------------+
//|                                           C_VisualRenderer.mqh   |
//|                             Lula Price Action Execution Engine V3|
//+------------------------------------------------------------------+
#ifndef C_VISUALRENDERER_MQH
#define C_VISUALRENDERER_MQH

#include "../Sprint1_Sensors/CZigZagEngine.mqh"
#include "../Sprint1_Sensors/C_OrderBlockSensor.mqh"

class C_VisualRenderer
{
public:
    static void DrawZigZag(CZigZagEngine *zz, string prefix, color clr)
    {
        if(zz == NULL) return;
        SZZNode nodes[];
        int count = zz.GetNodes(50, nodes);
        for(int i = 0; i < count - 1; i++)
        {
            string name = prefix + "_ZZ_" + IntegerToString(i);
            if(ObjectFind(0, name) < 0)
                ObjectCreate(0, name, OBJ_TREND, 0, nodes[i].time, nodes[i].price, nodes[i+1].time, nodes[i+1].price);
            else
            {
                ObjectMove(0, name, 0, nodes[i].time, nodes[i].price);
                ObjectMove(0, name, 1, nodes[i+1].time, nodes[i+1].price);
            }
            ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
        }
    }

    static void DrawOrderBlocks(C_OrderBlockSensor *obSensor)
    {
        if(obSensor == NULL) return;
        int count = obSensor.GetBlockCount();
        for(int i = 0; i < count; i++)
        {
            SOrderBlock ob = obSensor.GetBlock(i);
            if(!ob.isActive) continue;
            string name = "OB_" + IntegerToString(ob.time);
            if(ObjectFind(0, name) < 0)
            {
                ObjectCreate(0, name, OBJ_RECTANGLE, 0, ob.time, ob.top, ob.time + PeriodSeconds(PERIOD_H1) * 10, ob.bottom);
                ObjectSetInteger(0, name, OBJPROP_COLOR, ob.isBullish ? clrGreen : clrRed);
                ObjectSetInteger(0, name, OBJPROP_FILL, true);
                ObjectSetInteger(0, name, OBJPROP_BACK, true);
            }
        }
    }

    static void Clear(string prefix = "")
    {
        ObjectsDeleteAll(0, prefix);
    }
};

#endif // C_VISUALRENDERER_MQH
