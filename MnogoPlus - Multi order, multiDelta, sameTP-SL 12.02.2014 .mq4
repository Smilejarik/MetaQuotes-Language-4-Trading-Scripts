//+------------------------------------------------------------------+
//|Открытие много ордеров при разном расстоянии между ними и коеф. увеличения |
//| при этом тейк и стоп общий, "оптимальные" параметры включены |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#define MAGICMA  20050610

extern double Lots               = 0.1;
extern double TakeProfit         = 250;
extern double StopLoss           = 250;
extern double Otkat              = 600;
extern double BarSearch          = 30;
extern double Delta              = 60;
extern double Kolichestvo        = 8;
extern double Mnoznik            = 16;
extern double Hvatit             = 220;
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
         if(OrderType()==OP_BUY  || OrderType()==OP_BUYLIMIT)  buys++;
         if(OrderType()==OP_SELL || OrderType()==OP_SELLLIMIT) sells++;
        }
     }
//---- return orders volume
   if(buys>0) return(buys);
   else       return(sells);
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
      if(lot>7) 
         {
         lot=6.4;
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
   int    res, i, k;
   datetime o;
   int    type=1;
   double min=5;
   double max=0;
   double Price, LotPlus, Profit=0, Stop=0;
 
   
//---- go trading only for first tiks of new bar
   if(Volume[0]>1) return;   
  
 if(CalculateCurrentOrders(Symbol())==0) 
  {
   // проверка на покупку/продажу и смена действия   
  int accTotal=OrdersHistoryTotal();
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
 
    if(type==2)
       {
         for(i=2;i<BarSearch;i++) {
           if (Low[i]<min) {
           min=Low[i];
         //  Alert("Min найден",min,"номер свечи",i);
           }
         }
       }
    if(type==1)
       {
          for(i=2;i<BarSearch;i++) {
           if (High[i]>max) {
           max=High[i];
        //   Alert("Max найден",max,"номер свечи",i);
           }
         }
       }
   
//---- sell conditions
   if((Close[1]-min)>Otkat*Point)  
     {
    //  Alert("Разница:",Close[1]-min);
      StopLoss=Delta*(Kolichestvo+1)*10;
      TakeProfit=Hvatit*20;
      res=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Ask+StopLoss*Point,Bid-TakeProfit*Point,"",MAGICMA,0,Red);
      return;
     }
//---- buy conditions
   if((max-Close[1])>Otkat*Point)  
     {
   //   Alert("Разница:",max-Close[1]);
      StopLoss=Delta*(Kolichestvo+1)*10;
      TakeProfit=Hvatit*20;
      res=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Bid-StopLoss*Point,Ask+TakeProfit*Point,"",MAGICMA,0,Blue);
      return;
     }
   }
     
        if(OrdersTotal()==1) 
          {
            for(i=0;i<Kolichestvo;i++)
             {
              if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
              if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
                {
                   if(OrderType()==OP_BUY || OrderType()==OP_BUYLIMIT) 
                   {
                      Price=OrderOpenPrice()-NormalizeDouble(Delta/10000,3);
                      LotPlus=NormalizeDouble(OrderLots()*Mnoznik/10,1);
                      StopLoss=Delta*(Kolichestvo+1)*10;
                      TakeProfit=Hvatit*20;
                      res=OrderSend(Symbol(),OP_BUYLIMIT,LotPlus,Price,3,Bid-StopLoss*Point,Ask+TakeProfit*Point,"",MAGICMA,0,Blue);
                   }
                   if(OrderType()==OP_SELL || OrderType()==OP_SELLLIMIT) 
                   {
                      Price=OrderOpenPrice()+NormalizeDouble(Delta/10000,3);
                      LotPlus=NormalizeDouble(OrderLots()*Mnoznik/10,1);
                      StopLoss=Delta*(Kolichestvo+1)*10;
                      TakeProfit=Hvatit*20;
                      res=OrderSend(Symbol(),OP_SELLLIMIT,LotPlus,Price,3,Ask+StopLoss*Point,Bid-TakeProfit*Point,"",MAGICMA,0,Red);
                   }
                }
             }
      
          }

// если хотя бы один закроется (первый) по тейку то стоп=1 и закрываются все остальные
     for(i=0;i<OrdersHistoryTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if (OrderType()==OP_BUY || OrderType()==OP_SELL) 
              {
                if(OrderClosePrice()==OrderTakeProfit()) Stop=1;
                else Stop=0;
              }
        }
     }
     
     
   if (Stop==1)
    {
     for(i=0;i<=Kolichestvo;i++)
     {
      if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY) OrderClose(OrderTicket(),OrderLots(),Bid,3,White);
         if(OrderType()==OP_SELL) OrderClose(OrderTicket(),OrderLots(),Ask,3,White);
         if(OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLLIMIT) OrderDelete(OrderTicket());
        }
     }  
    }
     
//----
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
  double Profit=0;
//---- go trading only for first tiks of new bar
   if(Volume[0]>1) return;

//----

      for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         Profit=Profit+OrderProfit();
        }
     }
          
     
   if (Profit>Hvatit)
    {
     for(i=0;i<=Kolichestvo;i++)
     {
      if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY) OrderClose(OrderTicket(),OrderLots(),Bid,3,White);
         if(OrderType()==OP_SELL) OrderClose(OrderTicket(),OrderLots(),Ask,3,White);
         if(OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLLIMIT) OrderDelete(OrderTicket());
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
    if(CalculateCurrentOrders(Symbol())<(Kolichestvo+1)) CheckForOpen();
   else                                    CheckForClose();
//----
  }
//+------------------------------------------------------------------+