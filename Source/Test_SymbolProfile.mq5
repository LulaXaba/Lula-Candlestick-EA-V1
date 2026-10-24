//+------------------------------------------------------------------+
//|                                          Test_SymbolProfile.mq5  |
//|                             Lula Price Action Execution Engine V2|
//+------------------------------------------------------------------+
#property strict
void OnTick() {}

#include "Include\SymbolClass.mqh"
#include "Sprint1_Sensors\CZigZagEngine.mqh"

void RunUnitTests()
{
   PrintFormat("Detect(\"Boom 150 Index\") == SYM_SPIKY_SYNTH: %s (got %d)", 
      CSymbolProfile::Detect("Boom 150 Index") == SYM_SPIKY_SYNTH ? "PASS" : "FAIL", 
      CSymbolProfile::Detect("Boom 150 Index"));
      
   PrintFormat("Detect(\"EURUSD\") == SYM_FOREX: %s (got %d)", 
      CSymbolProfile::Detect("EURUSD") == SYM_FOREX ? "PASS" : "FAIL", 
      CSymbolProfile::Detect("EURUSD"));
      
   PrintFormat("Detect(\"VIX75\") == SYM_VOLATILE_SYNTH: %s (got %d)", 
      CSymbolProfile::Detect("VIX75") == SYM_VOLATILE_SYNTH ? "PASS" : "FAIL", 
      CSymbolProfile::Detect("VIX75"));

   CZigZagEngine zzH4, zzD1, zzW1;
   zzH4.Init("EURUSD", PERIOD_H4, 5000);
   zzD1.Init("EURUSD", PERIOD_D1, 10000);
   zzW1.Init("EURUSD", PERIOD_W1, 20000);
   PrintFormat("EURUSD zzH4: bars=%d state=%s", iBars("EURUSD", PERIOD_H4), EnumToString(zzH4.GetTrendState()));
   PrintFormat("EURUSD zzD1: bars=%d state=%s", iBars("EURUSD", PERIOD_D1), EnumToString(zzD1.GetTrendState()));
   PrintFormat("EURUSD zzW1: bars=%d state=%s", iBars("EURUSD", PERIOD_W1), EnumToString(zzW1.GetTrendState()));
}

int OnInit()
{
   RunUnitTests();
   return INIT_FAILED;
}
