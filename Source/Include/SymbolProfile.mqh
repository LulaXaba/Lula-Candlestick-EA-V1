//+------------------------------------------------------------------+
//|                                                SymbolProfile.mqh |
//|                             Lula Price Action Execution Engine V2|
//+------------------------------------------------------------------+
#ifndef SYMBOLPROFILE_MQH
#define SYMBOLPROFILE_MQH

enum ENUM_SYMBOL_CLASS {
   SYM_FOREX,           // EURUSD, GBPUSD, USDJPY, etc.
   SYM_SPIKY_SYNTH,     // Boom 500/1000/150, Crash series
   SYM_VOLATILE_SYNTH,  // VIX75, VIX 25, other volatility indices
   SYM_METAL,           // XAUUSD, XAGUSD
   SYM_OTHER
};

struct SSymbolProfile {
   ENUM_SYMBOL_CLASS cls;
   string  name;

   // --- Daily wick filter (context analyzer) ---
   double  daily_wick_max_long;    // upper-wick/range limit for longs
   double  daily_wick_max_short;   // lower-wick/range limit for shorts

   // --- Detector structural thresholds ---
   double  forcebar_min_body_pct;  // body/range minimum
   double  pinbar_min_wick_ratio;  // wick/range minimum
   double  pinbar_close_pct;       // close threshold as % of range
   double  star_exhaustion_pct;    // max body2/range2
   double  engulfing_min_body_pts; // minimum body in price points

   // --- Structural pullback variance ---
   double  hl_variance_atr_mult;   // HL tolerance as H1 ATR multiple

   // --- Local extreme lookback ---
   int     local_extreme_lookback;

   // --- Dynamic ZigZag Depth ATR Multipliers ---
   double  zz_depth_atr_mult_h4;
   double  zz_depth_atr_mult_d1;
   double  zz_depth_atr_mult_w1;
};

class CSymbolProfile {
public:
   static ENUM_SYMBOL_CLASS Detect(const string symbol);
   static SSymbolProfile    Get(const string symbol);   // cached
};

//+------------------------------------------------------------------+
//| Auto-detect symbol classification based on ticker name           |
//+------------------------------------------------------------------+
inline ENUM_SYMBOL_CLASS CSymbolProfile::Detect(const string sym) {
   string s = sym;
   StringToUpper(s);
   if(StringFind(s, "BOOM") >= 0 || StringFind(s, "CRASH") >= 0) return SYM_SPIKY_SYNTH;
   if(StringFind(s, "VIX")  >= 0 || StringFind(s, "VOLATILITY") >= 0 || StringFind(s, "STEP") >= 0) return SYM_VOLATILE_SYNTH;
   if(StringFind(s, "XAU")  >= 0 || StringFind(s, "XAG") >= 0 || StringFind(s, "GOLD") >= 0 || StringFind(s, "SILVER") >= 0)   return SYM_METAL;
   if(StringLen(sym) >= 6 && StringLen(sym) <= 7) return SYM_FOREX;
   return SYM_OTHER;
}

//+------------------------------------------------------------------+
//| Get tuned profile parameters for symbol                          |
//+------------------------------------------------------------------+
inline SSymbolProfile CSymbolProfile::Get(const string symbol) {
   static SSymbolProfile cache;
   static string cached_for = "";
   if(cached_for == symbol) return cache;

   cache.cls  = Detect(symbol);
   cache.name = symbol;

   string upper = symbol;
   StringToUpper(upper);

   switch(cache.cls) {
      case SYM_FOREX:
         cache.daily_wick_max_long   = 0.60;
         cache.daily_wick_max_short  = 0.60;
         cache.forcebar_min_body_pct = 0.80;
         cache.pinbar_min_wick_ratio = 0.65;
         cache.pinbar_close_pct      = 0.50;
         cache.star_exhaustion_pct   = 0.30;
         cache.engulfing_min_body_pts= 2 * _Point;
         cache.hl_variance_atr_mult  = 0.25;
         cache.local_extreme_lookback= 8;
         cache.zz_depth_atr_mult_h4  = 2.0;   // (~30 pips on H1 ATR)
         cache.zz_depth_atr_mult_d1  = 3.5;   // (~55 pips, daily swings)
         cache.zz_depth_atr_mult_w1  = 5.0;   // (~80 pips, weekly swings)
         break;

      case SYM_SPIKY_SYNTH:               // Boom / Crash
         if(StringFind(upper, "CRASH") >= 0) {
            // Crash has downward spikes (massive lower wicks)
            cache.daily_wick_max_long   = 0.55;
            cache.daily_wick_max_short  = 0.90;
         } else {
            // Boom has upward spikes (massive upper wicks)
            cache.daily_wick_max_long   = 0.90;
            cache.daily_wick_max_short  = 0.55;
         }
         cache.forcebar_min_body_pct = 0.50;
         cache.pinbar_min_wick_ratio = 0.45;
         cache.pinbar_close_pct      = 0.35;
         cache.star_exhaustion_pct   = 0.45;
         cache.engulfing_min_body_pts= 1 * _Point;
         cache.hl_variance_atr_mult  = 0.60;  // pullbacks are wide on Boom/Crash
         cache.local_extreme_lookback= 15;
         cache.zz_depth_atr_mult_h4  = 15.0;
         cache.zz_depth_atr_mult_d1  = 40.0;
         cache.zz_depth_atr_mult_w1  = 100.0;
         break;

      case SYM_VOLATILE_SYNTH:            // VIX75, etc.
         cache.daily_wick_max_long   = 0.80;  // mean-reverting, huge wicks both sides
         cache.daily_wick_max_short  = 0.80;
         cache.forcebar_min_body_pct = 0.60;
         cache.pinbar_min_wick_ratio = 0.55;
         cache.pinbar_close_pct      = 0.40;
         cache.star_exhaustion_pct   = 0.40;
         cache.engulfing_min_body_pts= 1 * _Point;
         cache.hl_variance_atr_mult  = 0.45;
         cache.local_extreme_lookback= 12;
         cache.zz_depth_atr_mult_h4  = 15.0;
         cache.zz_depth_atr_mult_d1  = 40.0;
         cache.zz_depth_atr_mult_w1  = 100.0;
         break;

      case SYM_METAL:                     // XAU, XAG
         cache.daily_wick_max_long   = 0.65;
         cache.daily_wick_max_short  = 0.65;
         cache.forcebar_min_body_pct = 0.65;
         cache.pinbar_min_wick_ratio = 0.55;
         cache.pinbar_close_pct      = 0.45;
         cache.star_exhaustion_pct   = 0.35;
         cache.engulfing_min_body_pts= 3 * _Point;
         cache.hl_variance_atr_mult  = 0.30;
         cache.local_extreme_lookback= 10;
         cache.zz_depth_atr_mult_h4  = 10.0;
         cache.zz_depth_atr_mult_d1  = 25.0;
         cache.zz_depth_atr_mult_w1  = 60.0;
         break;

      default:
         // Safe fallback = forex defaults
         cache.daily_wick_max_long   = 0.60;
         cache.daily_wick_max_short  = 0.60;
         cache.forcebar_min_body_pct = 0.75;
         cache.pinbar_min_wick_ratio = 0.60;
         cache.pinbar_close_pct      = 0.50;
         cache.star_exhaustion_pct   = 0.30;
         cache.engulfing_min_body_pts= 2 * _Point;
         cache.hl_variance_atr_mult  = 0.30;
         cache.local_extreme_lookback= 10;
         cache.zz_depth_atr_mult_h4  = 6.0;
         cache.zz_depth_atr_mult_d1  = 18.0;
         cache.zz_depth_atr_mult_w1  = 45.0;
         break;
   }
   cached_for = symbol;
   return cache;
}

#endif // SYMBOLPROFILE_MQH
