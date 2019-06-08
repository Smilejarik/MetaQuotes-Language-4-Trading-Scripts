//+------------------------------------------------------------------+
//|                                               Moving Average.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#define MAGICMA  20050610

extern double Lots               = 0.1;
extern double TakeProfit         = 1000;
extern double StopLoss           = 700;
extern double TrS                = 1100;
extern double MovingPeriod       = 25;
extern double MovingMnoz         = 2;
extern double Otkat              = 700;
extern double BarSearch          = 30;
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
                //Alert("Профит и лот определен!");
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
   int    mona;
   double ma;
   double Moving2;
   double ma500;
   double min=5;
   double max=0;
   double nmin;
   double nmax;
 
 
//---- go trading only for first tiks of new bar
   if(Volume[0]>1) return;  
   
   ma=iMA(NULL,0,MovingPeriod,0,MODE_SMA,PRICE_CLOSE,0);
   Moving2=NormalizeDouble(MovingPeriod*MovingMnoz/10,0);
   
   ma500=iMA(NULL,0,Moving2,0,MODE_SMA,PRICE_CLOSE,0);  
   
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
     if(ma500-ma>0.001)  
           {
           type=2;
           mona=1;
             if (OrderProfit()<0)   // если предидущий был убыток то ждем отката
                   {
                    mona=0;
                   }
          // Alert("Look for Minimum");
           }
         if(ma-ma500>0.001) 
           {
           type=1;
           mona=1;
             if (OrderProfit()<0)  // если предидущий был убыток то ждем отката
                   {
                    mona=0;
                   }
         //  Alert("Look for MAX");
           }
    }

  //Скользящее среднее
     

             if (type==2 && mona==0)   // если предидущий был убыток то ждем отката
                   {
                      for(i=2;i<BarSearch;i++) 
                       {
                        if (Low[i]<min) 
                          {
                            min=Low[i];
                            nmin=i;
                            //  Alert("Min найден",min,"номер свечи",i);
                          }
                        if (High[i]>max) 
                          {
                            max=High[i];
                            nmax=i;
                            //  Alert("MAX найден",max,"номер свечи",i);
                          }
                       }
                       if((max-min)>Otkat*Point && nmax<nmin)  // если откат прошел можно дальше торговать так же:
                          {
                           mona=1;
                          }
                   }
                   
            if (type==1 && mona==0)   // если предидущий был убыток то ждем отката
                   {
                      for(i=2;i<BarSearch;i++) 
                       {
                        if (Low[i]<min) 
                          {
                            min=Low[i];
                            nmin=i;
                            //  Alert("Min найден",min,"номер свечи",i);
                          }
                        if (High[i]>max) 
                          {
                            max=High[i];
                            nmax=i;
                            //  Alert("MAX найден",max,"номер свечи",i);
                          }
                       }
                       if((max-min)>Otkat*Point && nmax>nmin)  // если откат прошел можно дальше торговать так же:
                          {
                           mona=1;
                          }
                   }


// type-максимум или минимум, barsearch -количество баров
 //---- sell conditions
    if(type==2 && mona==1)
       {
          if((ma+0.001)>Close[1] && Close[1]>(ma-0.001))  //если это сходится то торгуем сразу
             {
            // Alert("ща продам");
               res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,Ask+StopLoss*Point,Bid-TakeProfit*Point,"",MAGICMA,0,Red);
               
               return;
             }
       }
       //---- buy conditions
    if(type==1 && mona==1)
       {
           if((ma+0.001)>Close[1] && Close[1]>(ma-0.001))   
             {
               //  Alert("ща куплю");
               res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,Bid-StopLoss*Point,Ask+TakeProfit*Point,"",MAGICMA,0,Blue);
              
               return;
             }
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
        
           return(0);
          }
        }
      if(OrderType()==OP_SELL)
        {
         if((OrderOpenPrice()-Low[1])>TrS*Point) 
         {
           OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-Point*20,OrderTakeProfit(),0,Blue);
          
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