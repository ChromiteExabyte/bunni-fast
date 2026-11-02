package MapItems.FruitTrees
{
   import Art.LoadArt;
   import Drawing.BitmapFrame;
   import FSM.StateMachine;
   import Geom.Circle;
   import Land.Land;
   import MapItems.FruitTrees.States.Grow;
   import MapItems.FruitTrees.States.Shake;
   import MapItems.GenericItem;
   import MapItems.StoreItems.StoreItem;
   import MapItems.StoreItems.StoreItemsList;
   import MapItems.Terrain.GardenItems.*;
   import MapItems.Terrain.HillItems.*;
   import MapItems.Treasure.TreasureChest;
   import Sound.Attenuation;
   import World.World;
   import flash.events.TimerEvent;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.utils.Timer;

   public class FruitTree extends GenericItem
   {

      private static var createFruit:Boolean;

      private static var staticTimer:Timer;

      public var mGrowthRate:Number;

      public var mFruitArt:BitmapFrame;

      public var mFruitArray:Array = new Array();

      public var mCanShake:Boolean = false;

      private var mStoreBubbleArray:Array = new Array();

      public function FruitTree(param1:int, param2:int)
      {
         super();
         this.mGrowthRate = 0.005;
         this.init(param1,param2,LoadArt.mFruitTree.getFrame(1),new Circle(param1,param2,50));
      }

      public static function Init() : void
      {
         createFruit = false;
         staticTimer = new Timer(60000,1);
         staticTimer.addEventListener(TimerEvent.TIMER_COMPLETE,createSeed);
         staticTimer.start();
      }

      private static function createSeed(param1:TimerEvent) : *
      {
         createFruit = true;
      }

      override public function initStateMachine() : void
      {
         mStateMachine = new StateMachine(this);
         mStateMachine.SetCurrentState(new Grow());
      }

      public function RemoveOne() : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         if(this.mCanShake)
         {
            if(this.mFruitArray.length > 0)
            {
               if(mStateMachine)
               {
                  mStateMachine.ChangeState(new Shake());
                  this.mFruitArray.pop();
                  _loc1_ = this.x + Math.random() * 100 - 50;
                  _loc2_ = this.y + Math.random() * 60;
                  if(this is AppleTree)
                  {
                     new PosieItem(LoadArt.mFruits.getFrame(1),_loc1_,_loc2_,0,new Circle(_loc1_,_loc2_,22),null,false,true);
                  }
                  else if(this is PearTree)
                  {
                     new TulipItem(LoadArt.mFruits.getFrame(2),_loc1_,_loc2_,0,new Circle(_loc1_,_loc2_,22),null,false,true);
                  }
                  else if(this is PlumTree)
                  {
                     new RoseItem(LoadArt.mFruits.getFrame(3),_loc1_,_loc2_,0,new Circle(_loc1_,_loc2_,22),null,false,true);
                  }
               }
            }
         }
      }

      override public function Update() : void
      {
         var _loc1_:int = 0;
         if(mStateMachine)
         {
            mStateMachine.Update();
         }
         _loc1_ = 0;
         while(_loc1_ < this.mStoreBubbleArray.length)
         {
            ++this.mStoreBubbleArray[_loc1_].time;
            if(this.mStoreBubbleArray[_loc1_].time > this.mStoreBubbleArray[_loc1_].over)
            {
               trace("removing item",this.mStoreBubbleArray[_loc1_].store);
               if(StoreItem(this.mStoreBubbleArray[_loc1_].store))
               {
                  StoreItem(this.mStoreBubbleArray[_loc1_].store).Pop();
                  this.mStoreBubbleArray.splice(_loc1_,1);
               }
               else
               {
                  this.mStoreBubbleArray.splice(_loc1_,1);
               }
            }
            _loc1_++;
         }
         if(this.mStoreBubbleArray.length > 0)
         {
            trace(this.mStoreBubbleArray);
         }
      }

      public function RemoveFruit() : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:Number = NaN;
         var _loc5_:TreasureChest = null;
         _loc3_ = 0;
         while(_loc3_ < this.mFruitArray.length)
         {
            _loc1_ = this.x + Math.random() * 100 - 50;
            _loc2_ = this.y + Math.random() * 60;
            if(createFruit)
            {
               createFruit = false;
               staticTimer = new Timer(60000,1);
               staticTimer.addEventListener(TimerEvent.TIMER_COMPLETE,createSeed);
               staticTimer.start();
               if(this is AppleTree)
               {
                  this.mStoreBubbleArray.push({
                     "store":StoreItemsList.MakeStore("Apple Tree",_loc1_,_loc2_,true),
                     "time":0,
                     "over":(Math.random() * 10 + 1) * 200
                  });
               }
               else if(this is PearTree)
               {
                  this.mStoreBubbleArray.push({
                     "store":StoreItemsList.MakeStore("Pear Tree",_loc1_,_loc2_,true),
                     "time":0,
                     "over":(Math.random() * 10 + 1) * 200
                  });
               }
               else if(this is PlumTree)
               {
                  this.mStoreBubbleArray.push({
                     "store":StoreItemsList.MakeStore("Legendary Plum Tree",_loc1_,_loc2_,true),
                     "time":0,
                     "over":(Math.random() * 10 + 1) * 200
                  });
               }
            }
            else if(Math.random() < 0.01)
            {
               this.mStoreBubbleArray.push({
                  "store":StoreItemsList.MakeRandomStore(_loc1_,_loc2_),
                  "time":0,
                  "over":(Math.random() * 10 + 1) * 200
               });
            }
            else
            {
               _loc4_ = Math.random();
               if(this is AppleTree)
               {
                  if(_loc4_ < 0.2)
                  {
                     _loc5_ = new TreasureChest(_loc1_,_loc2_);
                     _loc5_.SetRandom(1);
                  }
                  else
                  {
                     new PosieItem(LoadArt.mFruits.getFrame(1),_loc1_,_loc2_,0,new Circle(_loc1_,_loc2_,22),null,false,true);
                  }
               }
               else if(this is PearTree)
               {
                  if(_loc4_ < 0.3)
                  {
                     _loc5_ = new TreasureChest(_loc1_,_loc2_);
                     _loc5_.SetRandom(2);
                  }
                  else
                  {
                     new TulipItem(LoadArt.mFruits.getFrame(2),_loc1_,_loc2_,0,new Circle(_loc1_,_loc2_,22),null,false,true);
                  }
               }
               else if(this is PlumTree)
               {
                  if(_loc4_ < 0.2)
                  {
                     _loc5_ = new TreasureChest(_loc1_,_loc2_);
                     _loc5_.SetRandom(3);
                  }
                  else
                  {
                     new RoseItem(LoadArt.mFruits.getFrame(3),_loc1_,_loc2_,0,new Circle(_loc1_,_loc2_,22),null,false,true);
                  }
               }
            }
            _loc3_++;
         }
         this.mFruitArray = new Array();
      }

      public function Click() : void
      {
         if(this.mCanShake)
         {
            Attenuation.PlayPointSound("ShakeTree",new Point(this.x,this.y),1,1000);
            mStateMachine.ChangeState(new Shake());
            this.RemoveFruit();
         }
      }

      override public function draw() : void
      {
         var _loc2_:int = 0;
         var _loc3_:Matrix = null;
         var _loc4_:ColorTransform = null;
         if(!mArt)
         {
            trace("___WE HAVE NULL ART___");
            trace(this);
            trace(this.mID);
            throw new Error("___WE HAVE NULL ART___," + this + "," + this.mID);
         }
         drawx = x - World.WORLD_LOC_X;
         drawy = y / 2 - World.WORLD_LOC_Y;
         var _loc1_:Rectangle = new Rectangle(0,0,World.SCREEN_WIDTH,World.SCREEN_HEIGHT);
         if(mScale == 1)
         {
            itemRect = new Rectangle(drawx + mArt.hotspotX,drawy + mArt.hotspotY,mArt.mRect.width,mArt.mRect.height);
         }
         else
         {
            itemRect = new Rectangle(drawx + mArt.hotspotX * mScale,drawy + mArt.hotspotY * mScale,mArt.mRect.width * mScale,mArt.mRect.height * mScale);
         }
         if(_loc1_.intersects(itemRect))
         {
            if(mScale == 1 && mAlpha == 1)
            {
               Land.blit(mArt.bitmapData,mArt.mRect,drawx + mArt.hotspotX,drawy + mArt.hotspotY);
            }
            else
            {
               _loc3_ = new Matrix();
               _loc3_.translate(mArt.hotspotX,mArt.hotspotY);
               _loc3_.scale(mScale,mScale);
               _loc3_.translate(drawx,drawy);
               if(mAlpha != 1)
               {
                  _loc4_ = new ColorTransform();
                  _loc4_.alphaMultiplier = mAlpha;
               }
               Land.queue(mArt.bitmapData,_loc3_,_loc4_,null,true);
            }
         }
         _loc2_ = 0;
         while(_loc2_ < this.mFruitArray.length)
         {
            Land.blit(this.mFruitArt.bitmapData,this.mFruitArt.mRect,drawx + this.mFruitArray[_loc2_].x,drawy + this.mFruitArray[_loc2_].y);
            _loc2_++;
         }
      }
   }
}
