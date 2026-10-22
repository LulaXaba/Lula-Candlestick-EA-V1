//+------------------------------------------------------------------+
//|                                          Test_SymbolProfile.mq5  |
//|                             Lula Price Action Execution Engine V2|
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

#include "Include\SymbolClass.mqh"

void OnStart()
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

   SSymbolProfile profBoom = CSymbolProfile::Get("Boom 150 Index");
   PrintFormat("Boom 150 profile: name=%s cls=%d wick_long=%.2f wick_short=%.2f forcebar=%.2f pin_wick=%.2f pin_close=%.2f star=%.2f var_mult=%.2f lookback=%d",
      profBoom.name, profBoom.cls, profBoom.daily_wick_max_long, profBoom.daily_wick_max_short,
      profBoom.forcebar_min_body_pct, profBoom.pinbar_min_wick_ratio, profBoom.pinbar_close_pct,
      profBoom.star_exhaustion_pct, profBoom.hl_variance_atr_mult, profBoom.local_extreme_lookback);
}
