//+------------------------------------------------------------------+
//|                                         C_OrderBlockSensor.mqh   |
//|                             Lula Price Action Execution Engine V3|
//+------------------------------------------------------------------+
#ifndef C_ORDERBLOCKSENSOR_MQH
#define C_ORDERBLOCKSENSOR_MQH

class C_OrderBlockSensor
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_tf;

public:
                     C_OrderBlockSensor() : m_symbol(""), m_tf(PERIOD_CURRENT) {}
                    ~C_OrderBlockSensor() {}

   bool              Init(string symbol, ENUM_TIMEFRAMES tf)
   {
      m_symbol = symbol;
      m_tf = tf;
      return true;
   }

   void              Update() {}
   bool              IsInsideBullishOB(double price, double &sl) { return false; }
   bool              IsInsideBearishOB(double price, double &sl) { return false; }
};

#endif // C_ORDERBLOCKSENSOR_MQH
