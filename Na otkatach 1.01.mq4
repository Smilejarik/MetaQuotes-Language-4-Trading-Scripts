//+------------------------------------------------------------------+
//|                                               Moving Average.mq4 |
//|                      Copyright � 2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#define MAGICMA  20050610

extern double Lots               = 0.1;
extern double TakeProfit         = 400;
extern double StopLoss           = 200;
extern double Otkat              = 300;
extern int BarSearch             = 30;
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
 
// ���������� ������ ���� � ������ ���������� ������
 int i,accTotal=OrdersHistoryTotal();
  for(i=0;i<accTotal;i++)
    {
     //---- check selection result
     if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
       {
        Print("������ ��� ������� � ������������ ���� (",GetLastError(),")");
        break;
       }
     // ������ � ������� ...
             if (o<OrderCloseTime()) {
                o=OrderCloseTime();
                lot=OrderLots();
                p=OrderProfit();
                Alert("������ � ��� ���������!");
              }  
     }      
   
  
     
  if (p<0) 
   {
   lot=NormalizeDouble(lot*2,1);
   Alert("��� ������� �� 2");
   }
   else lot=Lots;   

  
//---- return lot size
   if(lot<0.1) 
   {
   lot=0.1;
   Alert("��� �������� �� 0.1");
   }
   
   
   if(lot>7) 
   {
   lot=6.4;
   Alert("��� �� ����");
   }
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
   int    timeframe=5;
   double min=5;
   double max=0;
//---- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
   
// �������� �� �������/������� � ����� ��������   
 int i,accTotal=OrdersHistoryTotal();
  for(i=0;i<accTotal;i++)
    {
     //---- check selection result
     if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
       {
        Print("������ ��� ������� � ������������ ���� (",GetLastError(),")");
        break;
       }
     // ������ � ������� ...
     if(OrderType()==OP_BUY)  
           {
           type=2;
           Alert("Look for Minimum");
           }
         if(OrderType()==OP_SELL) 
           {
           type=1;
           Alert("Look for MAX");
           }
    }
  
   
//������� ������ ���������/�������� �� �������� ���������� �����
// type-�������� ��� �������, barsearch -���������� �����
 
    if(type==2)
       {
         for(i=2;i<BarSearch;i++) {
           if (Low[i]<min) {
           min=Low[i];
           Alert("Min ������",min,"����� �����",i);
           }
         }
       }
    if(type==1)
       {
          for(i=2;i<BarSearch;i++) {
           if (High[i]>max) {
           max=High[i];
           Alert("Max ������",max,"����� �����",i);
           }
         }
       }


   
//---- sell conditions
   if((Close[1]-min)>Otkat*Point)  
     {
      Alert("�������:",Close[1]-min);
      res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,Ask+StopLoss*Point,Bid-TakeProfit*Point,"",MAGICMA,0,Red);
      return;
     }
//---- buy conditions
   if((max-Close[1])>Otkat*Point)  
     {
      Alert("�������:",max-Close[1]);
      res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,Bid-StopLoss*Point,Ask+TakeProfit*Point,"",MAGICMA,0,Blue);
      return;
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
   else                                    return;
//----
  }
//+------------------------------------------------------------------+