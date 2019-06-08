//+------------------------------------------------------------------+
//|                                               Moving Average.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#define MAGICMA  20050610

extern double Lots               = 0.1;
extern double TPmnoz             = 1.1;
extern double StopLoss           = 800;
extern double BarSearch          = 7;
extern double TrS                = 10000;
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//----
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//---- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
  double   lot=Lots;
  datetime o;
  double   p=1;
 
// определяем размер лота и профит последнего ордера
 int i,accTotal=OrdersHistoryTotal();
  for(i=0;i<accTotal;i++)
    {
     //---- check selection result
     if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
       {
        Print("Ошибка при доступе к исторической базе (",GetLastError(),")");
        break;
       }
     // работа с ордером ...
             if (o<OrderCloseTime()) {
                o=OrderCloseTime();
                lot=OrderLots();
                p=OrderProfit();
               // Alert("Профит и лот определен!");
              }  
     }      
   
  
     
  if (p<lot*100) 
   {
      if (p<-(lot*100)) 
      {
      lot=NormalizeDouble(lot*2,1);
      if(lot>2) 
         {
         lot=1.6;
         }
     //  Alert("Лот умножен на 2");
      }
      lot=NormalizeDouble(lot,1);
   }
   else lot=Lots;   
  
   
//---- return lot size
   if(lot<0.1) lot=0.1;
//   Alert("Лот уменьшен до 0.1");
   
  // Alert("Лот на макс");
   return(lot);
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   int    res;
   datetime o;
   int    type=1;
   double min=5;
   double max=0;
   double mona=0;
   double TakeProfit;
 
   
//---- go trading only for first tiks of new bar
   if(Volume[0]>1) return;  
   
// проверка на покупку/продажу и смена действия   
 int i,accTotal=OrdersHistoryTotal();
  for(i=0;i<accTotal;i++)
    {
     //---- check selection result
     if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
       {
        Print("Ошибка при доступе к исторической базе (",GetLastError(),")");
        break;
       }
     // работа с ордером ...
     if(OrderType()==OP_BUY)  
           {
           type=2;
          // Alert("Look for Minimum");
           }
         if(OrderType()==OP_SELL) 
           {
           type=1;
         //  Alert("Look for MAX");
           }
    }
  
   
//Функция поиска максимума/минимума за заданное количество баров
// type-максимум или минимум, barsearch -количество баров
 

         for(i=1;i<BarSearch;i++) 
         {
           if (Low[i]<min) {
           min=Low[i];
            // Alert("Min найден",min,"номер свечи",i);
           }
           if (High[i]>max) {
           max=High[i];
            // Alert("Max найден",max,"номер свечи",i);
           }
         }
        if (max-min<0.003)
         {
          mona=1;
         } 
         else mona=0;  
   
   TakeProfit=NormalizeDouble(StopLoss*TPmnoz,0);
//---- sell conditions
   if(type==2 && mona==1)  
     {
    //  Alert("Разница:",Close[1]-min);
      res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,Ask+StopLoss*Point,Bid-TakeProfit*Point,"",MAGICMA,0,Red);
      return;
     }
//---- buy conditions
   if(type==1 && mona==1)  
     {
   //   Alert("Разница:",max-Close[1]);
      res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,Bid-StopLoss*Point,Ask+TakeProfit*Point,"",MAGICMA,0,Blue);
      return;
     }
//----
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
//---- go trading only for first tiks of new bar
   if(Volume[0]>1) return;

//----
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)        break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //---- check order type 
      if(OrderType()==OP_BUY)
        {
         if((High[1]-OrderOpenPrice())>TrS*Point) 
          {
           OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+Point*20,OrderTakeProfit(),0,Blue);
          // lot=lot/2;
           return(0);
          }
        }
      if(OrderType()==OP_SELL)
        {
         if((OrderOpenPrice()-Low[1])>TrS*Point) 
         {
           OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-Point*20,OrderTakeProfit(),0,Blue);
           //lot=lot/2;
           return(0);
          }
        }
     }
//----
  }
//+------------------------------------------------------------------+
//| Start function                                                   |
//+------------------------------------------------------------------+
void start()
  {
//---- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false) return;
//---- calculate open orders by current symbol
    if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   else                                    CheckForClose();
//----
  }
//+------------------------------------------------------------------+