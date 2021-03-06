// create instance of Ctrade
#include <Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// params for M5
input int    TP_level  = 50;  // Take Profit (in pips)
input int    SL_level  = 600;  // Stop Loss Level (in pips)
input double start_lot = 0.01;  // Start lot
input double MAX_lot   = 0.16;  // max possible lot
input int    MA_period = 8;
input int    MA_dif    = 30;  // defference (minimum gap) between MA and open/close price

// globals
double lot = start_lot;
double price_ma_dif;
double order_profit = 0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

// Get the ask-bid prices
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   int MA_Simple = iMA(_Symbol,_Period,MA_period,0,MODE_SMA,PRICE_MEDIAN);
   double MA_Array[];
   
// Create price array
   MqlRates PriceInfo[];

// sort the price array from the current candle
   ArraySetAsSeries(PriceInfo, true);
   ArraySetAsSeries(MA_Array, true);

// Fill the array with the prices data
   int PriceData = CopyRates(
                      _Symbol, // curr symbol like EURUSD
                      _Period, // curr period like H1
                      0, // first candle
                      3, // take 3 candles
                      PriceInfo // copy into PriceInfo array
                   );

// Fill array for MA Simple, one line, current candle, 3 candles, store result:
   CopyBuffer(MA_Simple,0,0,3,MA_Array);
   
// Lot calculation here
//lot = calc_lot();
//lot = 0.1;


// buy when candle is Up and no opened positions:
   if(PositionsTotal()==0)
     {
     price_ma_dif = NormalizeDouble((MA_Array[0] - (Ask + Bid)/2),4);
      if((PriceInfo[1].close > PriceInfo[1].open) && (MA_Array[0]-Ask>MA_dif*_Point))  // below MA and price_ma_dif>MA_dif
        {
            // reversed
            price_ma_dif = NormalizeDouble((Bid - MA_Array[0]),4);
            Comment("Sell, trend Down: ", price_ma_dif," ", MA_dif*_Point);
            trade.Sell(
               calc_lot(), // how much,
               NULL, // current symbol
               Bid,  // buy price
               Bid+SL_level*_Point, // Stop Loss
               Bid-TP_level*_Point, // Take Profit
               "01_Simple"  // Comment
            );
        }
      else if((PriceInfo[1].close < PriceInfo[1].open) && (Bid-MA_Array[0]>MA_dif*_Point))  // Above MA and price_ma_dif>MA_dif
           {
           // reversed
               price_ma_dif = NormalizeDouble((MA_Array[0] - Ask),4);
               Comment("Buy, trend UP: ", price_ma_dif, " ", MA_dif*_Point);
               trade.Buy(
                  calc_lot(), // how much,
                  NULL, // current symbol
                  Ask,  // buy price
                  Ask-SL_level*_Point, // Stop Loss
                  Ask+TP_level*_Point, // Take Profit
                  "01_Simple"  // Comment
               );
           }
          
        
     }


  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calc_lot()
  {

   datetime end=TimeCurrent();  // the ending time set to the current server time
   datetime start=end-PeriodSeconds(PERIOD_MN1);// set the beginning for 24 hours ago
//--- request into the cache of the program the entire trading history
   HistorySelect(start,end);
//--- obtain the number of all of the orders in the history
   int history_orders=HistoryOrdersTotal();
//--- obtain the ticket of the order, which has the last index in the list, from the history
   ulong order_ticket=HistoryOrderGetTicket(history_orders-1);
   

   if(order_ticket>0)
     {
      //--- order profit
      order_profit = HistoryDealGetDouble(order_ticket, DEAL_PROFIT);
      lot = HistoryDealGetDouble(order_ticket, DEAL_VOLUME);
     }
   else
     {
      order_profit = 0;
     }

   if(order_profit<0)
     {
      lot = NormalizeDouble(lot*2, 2);
      if(lot>MAX_lot){lot=MAX_lot;}
      Print("--> Lot: ", lot, ", prev profit<0: ", order_profit, ", orders total: ", history_orders);
     }
   else
     {
      lot = NormalizeDouble(start_lot, 2);
      Print("--> Lot: ", lot, ", prev order profit: ", order_profit, ", orders total: ", history_orders);
     }

   return(lot);
  }
//+------------------------------------------------------------------+
