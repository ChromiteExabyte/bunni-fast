package Land
{
   import Drawing.*;
   import Drawing.events.BitmapDataUnlimitedEvent;
   import Geom.Circle;
   import Geom.Vector2D;
   import Collision.TestCollision;
   import Geom.Rndm;
   import MapItems.Items;
   import MapItems.StoreItems.BeaverItem;
   import MapItems.Terrain.*;
   import MapItems.Terrain.HillItems.*;
   import Switches.Switch;
   import World.*;
   import flash.display.*;
   import flash.events.TimerEvent;
   import flash.geom.*;
   import flash.filters.BlurFilter;
   import flash.utils.Timer;
   import flash.utils.getTimer;

   public class Land
   {

      private static var mCoveAngel:BeaverItem;

      private static var mShoreFrame:BitmapFrame;

      private static var mLandFrame:BitmapFrame;

      private static var mShadingFrame:BitmapFrame;

      private static var mShadingHillFrame:BitmapFrame;

      public static var mEntireMap:BitmapData;

      public static var mStage:MovieClip;

      public static var mBackgroundSprite:Sprite;

      public static var mBackgroundBitmap:Sprite;

      public static var mScreenBitmapData:BitmapData;

      public static var mLandArray:Array;

      private static var mCallback:Function;

      private static var mTimer:Timer;

      private static var mMapCallback:Function;

      private static const LAND_BLOCK_WIDTH:int = 600;

      private static const LAND_BLOCK_HEIGHT:int = 600;

      private static var mLastX:int = int.MAX_VALUE;

      private static var mLastY:int = int.MAX_VALUE;

      public static var WATER_GAP:int = 340;

      public static var WORLD_INSET:int = 140;

      private static var WORLD_THIRD:int = World.WORLD_WIDTH / 3;

      private static var mFirstBridge:Boolean = true;

      public static var mLandRectangles:Array = new Array();

      public static var mTextOut:MovieClip = new MovieClip();

      private static var bdu:BitmapDataUnlimited = new BitmapDataUnlimited();

      private static const mDivisor:int = 100;

      public function Land()
      {
         super();
      }

      public static function init(param1:MovieClip, param2:Function) : void
      {
         mCallback = param2;
         mStage = param1;
         mShoreFrame = new BitmapFrame();
         mShoreFrame.CreateFrameFromMovieClip(new Shore(),1,1.5);
         mLandFrame = new BitmapFrame();
         mLandFrame.CreateFrameFromMovieClip(new LandGround(),1,1.5);
         mShadingFrame = new BitmapFrame();
         mShadingFrame.CreateFrameFromMovieClip(new LandShading(),1,1.5);
         mShadingHillFrame = new BitmapFrame();
         mShadingHillFrame.CreateFrameFromMovieClip(new LandHillShading(),1,1.5);
         bdu.addEventListener(BitmapDataUnlimitedEvent.COMPLETE,onBmpReady);
         bdu.addEventListener(BitmapDataUnlimitedEvent.ERROR,onBmpError);
         bdu.create(World.WORLD_WIDTH + WORLD_INSET,World.WORLD_HEIGHT / 2 + WORLD_INSET,true,4283531204);
      }

      private static function onBmpReady(param1:BitmapDataUnlimitedEvent) : void
      {
         trace("bitmapready",getTimer());
         mEntireMap = bdu.bitmapData;
         mEntireMap.fillRect(mEntireMap.rect,4283531204);
         trace("filled",getTimer());
         DrawEntireMap();
         trace("drawmap",getTimer());
      }

      private static function onBmpError(param1:BitmapDataUnlimitedEvent) : void
      {
         trace("Can\'t create BitmapData");
      }

      public static function DrawBridge(param1:int, param2:int, param3:Boolean) : void
      {
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:Number = NaN;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc4_:int = param1;
         var _loc5_:int = param2;
         _loc6_ = -2;
         while(_loc6_ < 3)
         {
            _loc7_ = 0;
            _loc8_ = 0.5;
            _loc9_ = LAND_BLOCK_WIDTH * _loc8_;
            _loc10_ = LAND_BLOCK_HEIGHT * _loc8_;
            if(param3)
            {
               _loc4_ = param1 + _loc9_ / 2 * _loc6_;
               _loc5_ += Rndm.random() * 100 - 50;
            }
            else
            {
               _loc4_ += Rndm.random() * 100 - 50;
               _loc5_ = param2 + _loc10_ / 2 * _loc6_;
            }
            mLandArray.push({
               "circle":new Circle(_loc4_,_loc5_,_loc9_ / 2),
               "hill":true,
               "scale":_loc8_,
               "size":_loc7_
            });
            _loc6_++;
         }
      }

      private static function CreateLandArray(param1:Rectangle) : Array
      {
         var _loc7_:int = 0;
         var _loc8_:Number = NaN;
         var _loc9_:int = 0;
         var _loc10_:Circle = null;
         Rndm.seed = 2;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:Array = new Array();
         var _loc5_:int = 300;
         var _loc6_:int = 0;
         while(_loc3_ < 4 && _loc5_ > _loc6_)
         {
            _loc6_++;
            if(_loc2_ == 0)
            {
               _loc7_ = Rndm.random() * 3;
               _loc8_ = 1;
               if(_loc7_ == 0)
               {
                  _loc8_ = 0.5;
               }
               else if(_loc7_ == 1)
               {
                  _loc8_ = 0.66;
               }
               _loc9_ = LAND_BLOCK_WIDTH * _loc8_;
               _loc10_ = new Circle(Rndm.random() * param1.width + param1.x,Rndm.random() * param1.height + param1.y,_loc9_ / 2);
               _loc4_.push({
                  "circle":_loc10_,
                  "hill":false,
                  "rect":param1,
                  "scale":_loc8_,
                  "size":_loc7_
               });
               _loc3_ = 0;
            }
            else
            {
               _loc3_++;
            }
            _loc2_ = Distribute(param1,_loc4_);
         }
         return _loc4_;
      }

      private static function Distribute(param1:Rectangle, param2:Array) : int
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Circle = null;
         var _loc7_:Circle = null;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc11_:Number = NaN;
         _loc3_ = 0;
         while(_loc3_ < param2.length)
         {
            _loc6_ = param2[_loc3_].circle;
            _loc4_ = _loc3_ + 1;
            while(_loc4_ < param2.length)
            {
               _loc7_ = param2[_loc4_].circle;
               _loc8_ = _loc6_.r / 2 + _loc7_.r / 2;
               _loc9_ = _loc6_.x - _loc7_.x;
               _loc10_ = _loc6_.y - _loc7_.y;
               _loc11_ = Math.sqrt(_loc9_ * _loc9_ + _loc10_ * _loc10_);
               if(_loc11_ < _loc8_)
               {
                  _loc6_.x += -0.5 * (_loc11_ - _loc8_) * _loc9_ / _loc11_;
                  _loc6_.y += -0.5 * (_loc11_ - _loc8_) * _loc10_ / _loc11_;
                  _loc7_.x += 0.5 * (_loc11_ - _loc8_) * _loc9_ / _loc11_;
                  _loc7_.y += 0.5 * (_loc11_ - _loc8_) * _loc10_ / _loc11_;
               }
               if(!param1.containsPoint(new Point(_loc6_.x,_loc6_.y)))
               {
                  _loc6_.x = Rndm.random() * param1.width + param1.x;
                  _loc6_.y = Rndm.random() * param1.height + param1.y;
                  _loc5_++;
               }
               if(!param1.containsPoint(new Point(_loc7_.x,_loc7_.y)))
               {
                  _loc7_.x = Rndm.random() * param1.width + param1.x;
                  _loc7_.y = Rndm.random() * param1.height + param1.y;
                  _loc5_++;
               }
               _loc4_++;
            }
            _loc3_++;
         }
         return _loc5_;
      }

      private static function CreateSingleLand(param1:Rectangle, param2:String, param3:Number, param4:Number) : void
      {
         var _loc5_:int = 0;
         var _loc6_:Number = NaN;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         if(param2 == "small")
         {
            _loc5_ = 0;
            _loc6_ = 0.5;
         }
         else if(param2 == "medium")
         {
            _loc5_ = 1;
            _loc6_ = 0.66;
         }
         else if(param2 == "large")
         {
            _loc5_ = 2;
            _loc6_ = 1;
         }
         _loc7_ = LAND_BLOCK_WIDTH * _loc6_;
         _loc8_ = LAND_BLOCK_HEIGHT * _loc6_;
         var _loc9_:int = param3 * param1.width + param1.x;
         var _loc10_:int = param4 * param1.height + param1.y;
         mLandArray.push({
            "circle":new Circle(_loc9_,_loc10_,_loc7_ / 2),
            "hill":false,
            "scale":_loc6_,
            "size":_loc5_
         });
      }

      private static function DistributeLand() : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:Circle = null;
         var _loc5_:Circle = null;
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         _loc1_ = 0;
         while(_loc1_ < mLandArray.length)
         {
            if(mLandArray[_loc1_].rect)
            {
               _loc4_ = mLandArray[_loc1_].circle;
               _loc2_ = _loc1_ + 1;
               while(_loc2_ < mLandArray.length)
               {
                  if(mLandArray[_loc1_].rect == mLandArray[_loc2_].rect)
                  {
                     _loc5_ = mLandArray[_loc2_].circle;
                     _loc6_ = (_loc4_.r + _loc5_.r) / 2;
                     _loc7_ = _loc4_.x - _loc5_.x;
                     _loc8_ = _loc4_.y - _loc5_.y;
                     _loc9_ = Math.sqrt(_loc7_ * _loc7_ + _loc8_ * _loc8_);
                     if(_loc9_ < _loc6_)
                     {
                        _loc4_.x += -0.5 * (_loc9_ - _loc6_) * _loc7_ / _loc9_;
                        _loc4_.y += -0.5 * (_loc9_ - _loc6_) * _loc8_ / _loc9_;
                        _loc5_.x += 0.5 * (_loc9_ - _loc6_) * _loc7_ / _loc9_;
                        _loc5_.y += 0.5 * (_loc9_ - _loc6_) * _loc8_ / _loc9_;
                        if(_loc4_.x < mLandArray[_loc1_].rect.x)
                        {
                           _loc4_.x = mLandArray[_loc1_].rect.x;
                        }
                        if(_loc4_.x > mLandArray[_loc1_].rect.x + mLandArray[_loc1_].rect.width)
                        {
                           _loc4_.x = mLandArray[_loc1_].rect.x + mLandArray[_loc1_].rect.width;
                        }
                        if(_loc4_.y < mLandArray[_loc1_].rect.y)
                        {
                           _loc4_.y = mLandArray[_loc1_].rect.y;
                        }
                        if(_loc4_.y > mLandArray[_loc1_].rect.y + mLandArray[_loc1_].rect.height)
                        {
                           _loc4_.y = mLandArray[_loc1_].rect.y + mLandArray[_loc1_].rect.height;
                        }
                        if(_loc5_.x < mLandArray[_loc1_].rect.x)
                        {
                           _loc5_.x = mLandArray[_loc1_].rect.x;
                        }
                        if(_loc5_.x > mLandArray[_loc1_].rect.x + mLandArray[_loc1_].rect.width)
                        {
                           _loc5_.x = mLandArray[_loc1_].rect.x + mLandArray[_loc1_].rect.width;
                        }
                        if(_loc5_.y < mLandArray[_loc1_].rect.y)
                        {
                           _loc5_.y = mLandArray[_loc1_].rect.y;
                        }
                        if(_loc5_.y > mLandArray[_loc1_].rect.y + mLandArray[_loc1_].rect.height)
                        {
                           _loc5_.y = mLandArray[_loc1_].rect.y + mLandArray[_loc1_].rect.height;
                        }
                     }
                  }
                  _loc2_++;
               }
            }
            _loc1_++;
         }
      }

      private static function DrawLand(param1:XML) : Array
      {
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc9_:XML = null;
         var _loc10_:Rectangle = null;
         var _loc7_:* = new Array();
         var _loc8_:XMLList = param1.rect;
         Rndm.seed = 3;
         for each(_loc9_ in _loc8_)
         {
            _loc10_ = new Rectangle(_loc9_.x * World.WORLD_WIDTH,_loc9_.y * World.WORLD_HEIGHT,_loc9_.width * World.WORLD_WIDTH,_loc9_.height * World.WORLD_HEIGHT);
            _loc10_.inflate(-WATER_GAP,-WATER_GAP);
            _loc7_.push(_loc10_);
         }
         return _loc7_;
      }

      private static function DrawEntireMap() : void
      {
         var islandList:XMLList;
         var i:int = 0;
         var rnd:int = 0;
         var scale:Number = NaN;
         var partWidth:int = 0;
         var partHeight:int = 0;
         var x:int = 0;
         var y:int = 0;
         var island:XML = null;
         var bridge:XML = null;
         var bridgeList:XMLList = null;
         var beaverX:int = 0;
         var beaverY:int = 0;
         var beaverHorizontal:Boolean = false;
         mLandArray = [{
            "circle":new Circle(773,435,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(700,514,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(533,734,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(428,649,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(762,399,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(533,1017,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(463,1075,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(705,907,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(560,644,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(465,351,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(773,1920,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(700,1999,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(533,2219,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(428,2134,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(762,1884,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(533,2502,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(463,2560,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(705,2392,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(560,2129,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(465,1836,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(601,3890,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(1367,3469,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1451,3801,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(763,3818,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1244,3948,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1118,3812,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(450,3632,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1822,3538,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(756,3576,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(919,4016,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1553,3400,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1469,3646,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(1452,3959,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(727,4100,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1668,3790,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1336,4104,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(1023,3877,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(581,3496,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1660,4096,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1011,3664,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1164,3329,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1857,3316,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(942,3445,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1257,3615,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(357,3863,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(2851,3890,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(3617,3469,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(3701,3801,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(3013,3818,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3494,3948,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3368,3812,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(2700,3632,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(4072,3538,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3006,3576,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3169,4016,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(3803,3400,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3719,3646,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(3702,3959,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(2977,4100,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(3918,3790,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3586,4104,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(3273,3877,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(2831,3496,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(3910,4096,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3261,3664,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(3414,3329,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(4107,3316,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(3192,3445,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(3507,3615,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(2607,3863,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3813,2100,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(3964,766,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(4088,1822,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(3814,1544,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(4100,1301,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3960,1987,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(3940,1697,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(4095,2470,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(4021,561,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3727,503,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3824,1808,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3798,1123,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(4089,956,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(4066,1544,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(4094,1283,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(3829,2342,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(4005,2184,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(4009,1037,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(3766,906,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3945,1290,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(3863,2493,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(1726,920,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(2492,499,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(2576,831,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(1888,848,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(2369,978,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(2243,842,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1575,662,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(2947,568,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1881,606,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(2044,1046,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(2678,430,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(2594,676,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(2577,989,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1852,1130,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(2793,820,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(2461,1134,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(2148,907,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(1706,526,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(2785,1126,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(2136,694,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(2289,359,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(2982,346,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(2067,475,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(2382,645,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1482,893,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1563,2100,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(1714,766,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1838,1822,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(1564,1544,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1850,1301,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1710,1987,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1690,1697,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1845,2470,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1771,561,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1477,503,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1574,1808,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1548,1123,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1839,956,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1816,1544,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1844,1283,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(1579,2342,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(1755,2184,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1759,1037,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(1516,906,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(1695,1290,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(1613,2493,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(3023,1920,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(2950,1999,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(2783,2219,150),
            "hill":false,
            "scale":0.5,
            "size":0
         },{
            "circle":new Circle(2678,2134,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(3012,1884,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(2783,2502,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(2713,2560,198),
            "hill":false,
            "scale":0.66,
            "size":1
         },{
            "circle":new Circle(2955,2392,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(2810,2129,300),
            "hill":false,
            "scale":1,
            "size":2
         },{
            "circle":new Circle(2715,1836,300),
            "hill":false,
            "scale":1,
            "size":2
         }];
         trace("11",getTimer());
         islandList = Bunni.mXML.islands.island;
         for each(island in islandList)
         {
            mLandRectangles.push(DrawLand(island));
         }
         trace("12",getTimer());
         bridgeList = Bunni.mXML.bridges.bridge;
         for each(bridge in bridgeList)
         {
            beaverX = Number(bridge.location.x) * World.WORLD_WIDTH;
            beaverY = Number(bridge.location.y) * World.WORLD_HEIGHT;
            beaverHorizontal = bridge.horizontal == "true";
            if(bridge.name == "Pirate Cove")
            {
               mCoveAngel = new BeaverItem(beaverX,beaverY,bridge.name,bridge.description,int(bridge.costwood),int(bridge.costrock),int(bridge.costgem),beaverHorizontal);
            }
            else
            {
               new BeaverItem(beaverX,beaverY,bridge.name,bridge.description,int(bridge.costwood),int(bridge.costrock),int(bridge.costgem),beaverHorizontal);
            }
         }
         trace("13",getTimer());
         trace("14",getTimer());
         DrawEntireBitmap(function():void
         {
            mScreenBitmapData = new BitmapData(World.SCREEN_WIDTH,World.SCREEN_HEIGHT,true,4283531204);
            // bunni-fast: show the display-list screen instead of a Bitmap of mScreenBitmapData.
            InitScreen();
            mBackgroundBitmap = mScreen;
            mStage.addChild(mBackgroundBitmap);
            trace("end draw entire",getTimer());
            mCallback();
         });
      }

      public static function OpenFirst() : void
      {
         if(!Switch.IsOpen("firstbridge"))
         {
            Switch.FirstBridge();
            Land.DrawBridge(0.125 * World.WORLD_WIDTH,0.33 * World.WORLD_HEIGHT,false);
            World.PauseGame();
            DrawEntireBitmap(function():void
            {
               World.Continue();
            });
         }
      }

      public static function OpenSecond() : void
      {
         if(!Switch.IsOpen("secondbridge"))
         {
            Switch.SecondBridge();
            Land.DrawBridge(0.125 * World.WORLD_WIDTH,0.66 * World.WORLD_HEIGHT,false);
            World.PauseGame();
            DrawEntireBitmap(function():void
            {
               World.Continue();
            });
         }
      }

      public static function OpenPeteIsle() : void
      {
         if(!Switch.IsOpen("peteisle"))
         {
            Switch.PeteIsle();
            DrawBridge(0.5 * World.WORLD_WIDTH,0.825 * World.WORLD_HEIGHT,true);
            World.PauseGame();
            DrawEntireBitmap(function():void
            {
               World.Continue();
            });
         }
      }

      public static function OpenPirateCove() : void
      {
         if(!Switch.IsOpen("piratecove"))
         {
            Switch.PirateCove();
            DrawBridge(0.25 * World.WORLD_WIDTH,0.5 * World.WORLD_HEIGHT,true);
            DrawBridge(0.375 * World.WORLD_WIDTH,0.66 * World.WORLD_HEIGHT,false);
            World.mPeach.PirateCove();
            Items.RemoveItem(mCoveAngel);
            World.PauseGame();
            DrawEntireBitmap(function():void
            {
               World.Continue();
            });
         }
      }

      public static function OpenWeddingIsle() : void
      {
         if(!Switch.IsOpen("weddingisle"))
         {
            Switch.WeddingIsle();
            DrawBridge(0.875 * World.WORLD_WIDTH,0.66 * World.WORLD_HEIGHT,false);
            World.PauseGame();
            DrawEntireBitmap(function():void
            {
               World.Continue();
            });
         }
      }

      public static function OpenMonsterIsle() : void
      {
         if(!Switch.IsOpen("monsterisle"))
         {
            Switch.MonsterIsle();
            DrawBridge(0.625 * World.WORLD_WIDTH,0.33 * World.WORLD_HEIGHT,false);
            DrawBridge(0.625 * World.WORLD_WIDTH,0.66 * World.WORLD_HEIGHT,false);
            DrawBridge(0.75 * World.WORLD_WIDTH,0.5 * World.WORLD_HEIGHT,true);
            DrawBridge(0.5 * World.WORLD_WIDTH,0.5 * World.WORLD_HEIGHT,true);
            World.PauseGame();
            DrawEntireBitmap(function():void
            {
               World.Continue();
            });
         }
      }

      // bunni-fast: the original drew every land blob into the 4640x2390 map with its own draw() call,
      // spread over timer ticks (addShore/addLand/addShade). Each of those is a full offscreen render in
      // Ruffle, and on WebGL that hangs the tab for minutes. Same blobs, same order, one draw().
      public static function DrawEntireBitmap(param1:Function = null) : void
      {
         mPointGridSource = null;
         mMapCallback = param1;
         mViewportDirty = true;
         mLandArray.sortOn("y",Array.NUMERIC);
         mLandArray.sortOn("hill");
         var _loc2_:Sprite = new Sprite();
         var _loc3_:int = 0;
         _loc3_ = 0;
         while(_loc3_ < mLandArray.length)
         {
            AddToLayer(_loc2_,mShoreFrame,mLandArray[_loc3_]);
            _loc3_++;
         }
         _loc3_ = 0;
         while(_loc3_ < mLandArray.length)
         {
            AddToLayer(_loc2_,mLandFrame,mLandArray[_loc3_]);
            _loc3_++;
         }
         _loc3_ = 0;
         while(_loc3_ < mLandArray.length)
         {
            AddToLayer(_loc2_,!!mLandArray[_loc3_].hill ? mShadingHillFrame : mShadingFrame,mLandArray[_loc3_]);
            _loc3_++;
         }
         mEntireMap.draw(_loc2_);
         // Finish on a timer tick like the original did, so callers see the same event order.
         mTimer = new Timer(10,1);
         mTimer.addEventListener(TimerEvent.TIMER_COMPLETE,shadeDone);
         mTimer.start();
      }

      private static function AddToLayer(param1:Sprite, param2:BitmapFrame, param3:Object) : void
      {
         var _loc4_:Bitmap = new Bitmap(param2.bitmapData);
         _loc4_.transform.matrix = MapMatrix(param2,param3.circle.x,param3.circle.y / 2,param3.scale);
         param1.addChild(_loc4_);
      }

      private static function MapMatrix(param1:BitmapFrame, param2:int, param3:int, param4:Number) : Matrix
      {
         var _loc5_:Matrix = new Matrix();
         _loc5_.translate(param1.mHotSpotX,param1.mHotSpotY);
         _loc5_.scale(param4,param4);
         _loc5_.translate(param2 + WORLD_INSET / 2,param3 + WORLD_INSET / 2);
         return _loc5_;
      }

      private static function addShore(param1:TimerEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = (param1.target.currentCount - 1) * mDivisor;
         var _loc4_:int = Math.min(param1.target.currentCount * mDivisor - 1,mLandArray.length - 1);
         _loc2_ = _loc3_;
         while(_loc2_ <= _loc4_)
         {
            DrawToMap(mShoreFrame,mLandArray[_loc2_].circle.x,mLandArray[_loc2_].circle.y / 2,mLandArray[_loc2_].scale);
            _loc2_++;
         }
      }

      private static function addLand(param1:TimerEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = (param1.target.currentCount - 1) * mDivisor;
         var _loc4_:int = Math.min(param1.target.currentCount * mDivisor - 1,mLandArray.length - 1);
         _loc2_ = _loc3_;
         while(_loc2_ <= _loc4_)
         {
            DrawToMap(mLandFrame,mLandArray[_loc2_].circle.x,mLandArray[_loc2_].circle.y / 2,mLandArray[_loc2_].scale);
            _loc2_++;
         }
      }

      private static function addShade(param1:TimerEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = (param1.target.currentCount - 1) * mDivisor;
         var _loc4_:int = Math.min(param1.target.currentCount * mDivisor - 1,mLandArray.length - 1);
         _loc2_ = _loc3_;
         while(_loc2_ <= _loc4_)
         {
            if(mLandArray[_loc2_].hill)
            {
               DrawToMap(mShadingHillFrame,mLandArray[_loc2_].circle.x,mLandArray[_loc2_].circle.y / 2,mLandArray[_loc2_].scale);
            }
            else
            {
               DrawToMap(mShadingFrame,mLandArray[_loc2_].circle.x,mLandArray[_loc2_].circle.y / 2,mLandArray[_loc2_].scale);
            }
            _loc2_++;
         }
      }

      private static function shoreDone(param1:TimerEvent) : void
      {
         mTimer.removeEventListener(TimerEvent.TIMER,addShore);
         mTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,shoreDone);
         mTimer = null;
         mTimer = new Timer(10,Math.ceil(mLandArray.length / mDivisor));
         mTimer.addEventListener(TimerEvent.TIMER,addLand);
         mTimer.addEventListener(TimerEvent.TIMER_COMPLETE,landDone);
         mTimer.start();
      }

      private static function landDone(param1:TimerEvent) : void
      {
         mTimer.removeEventListener(TimerEvent.TIMER,addLand);
         mTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,landDone);
         mTimer = null;
         mTimer = new Timer(10,Math.ceil(mLandArray.length / mDivisor));
         mTimer.addEventListener(TimerEvent.TIMER,addShade);
         mTimer.addEventListener(TimerEvent.TIMER_COMPLETE,shadeDone);
         mTimer.start();
      }

      private static function shadeDone(param1:TimerEvent) : void
      {
         mTimer.removeEventListener(TimerEvent.TIMER,addShade);
         mTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,shadeDone);
         mTimer = null;
         if(Boolean(mMapCallback))
         {
            mMapCallback();
         }
      }

      private static function DrawToMap(param1:BitmapFrame, param2:int, param3:int, param4:Number) : *
      {
         if(param2 == 0 || param3 == 0)
         {
            trace("ZERO ERROR OCCURED x:",param2,"y:",param3);
         }
         var _loc5_:Matrix = new Matrix();
         _loc5_.translate(param1.mHotSpotX,param1.mHotSpotY);
         _loc5_.scale(param4,param4);
         _loc5_.translate(param2 + WORLD_INSET / 2,param3 + WORLD_INSET / 2);
         mEntireMap.draw(param1.bitmapData,_loc5_);
      }

      public static function mapDraw() : void
      {
         var _loc2_:Matrix = null;
         var _loc3_:Number = NaN;
         var _loc1_:Boolean = true;
         if(_loc1_)
         {
            BeginFrame();
            _loc2_ = new Matrix();
            _loc3_ = mScreenBitmapData.width / mEntireMap.width;
            _loc2_.scale(_loc3_,_loc3_);
            _loc2_.translate(0,64);
            queue(mEntireMap,_loc2_,null,null,true);
         }
      }

      public static function draw() : void
      {
         var _loc1_:Boolean = false;
         if(mLastX != World.WORLD_LOC_X)
         {
            _loc1_ = true;
         }
         if(mLastY != World.WORLD_LOC_Y)
         {
            _loc1_ = true;
         }
         if(_loc1_)
         {
            BeginFrame();
            QueueMapViewport();
         }
      }

      // bunni-fast: the screen is a display list instead of a bitmap.
      // The game built every frame by drawing each sprite into mScreenBitmapData with draw()/copyPixels()
      // and showing that bitmap. In Ruffle each draw() is its own offscreen GPU pass, each copyPixels()
      // after a draw() is a GPU->CPU readback, and the bitmap gets re-uploaded and re-allocated, which
      // kept Chrome's GPU process saturated (3-15 fps). Now the same calls add pooled Bitmap children,
      // in the same order with the same matrices, color transforms and blend modes, to mScreen, which
      // sits on the stage where the bitmap used to be. Ruffle renders it in its normal stage pass.
      // mBackgroundBitmap (only ever tweened: intro blur, bridge/store tints) now points at mScreen.
      // mScreenBitmapData still exists for width/height queries; the map viewport is separate.
      private static var mScreen:Sprite = new Sprite();

      // bunni-fast: keep the world-map display child physically screen-sized. scrollRect alone
      // does not prevent Ruffle's filter path from allocating for the full 4640x2390 child.
      // Crop through one bounded GPU pass. No map or screen pixels are read back to the CPU.
      private static var mMapViewport:BitmapData;
      private static var mMapCrop:Sprite;
      private static var mMapCropBitmap:Bitmap;
      private static var mViewportX:int = int.MAX_VALUE;
      private static var mViewportY:int = int.MAX_VALUE;
      private static var mViewportDirty:Boolean = true;
      private static var mViewportCopies:int = 0;

      private static function QueueMapViewport() : void
      {
         if(mMapViewport == null)
         {
            mMapViewport = new BitmapData(World.SCREEN_WIDTH,World.SCREEN_HEIGHT,false,5341124);
            mMapCrop = new Sprite();
            var water:Shape = new Shape();
            water.graphics.beginFill(5341124,1);
            water.graphics.drawRect(0,0,World.SCREEN_WIDTH,World.SCREEN_HEIGHT);
            water.graphics.endFill();
            mMapCrop.addChild(water);
            mMapCropBitmap = new Bitmap(mEntireMap);
            mMapCrop.addChild(mMapCropBitmap);
         }
         if(mViewportDirty || mViewportX != World.WORLD_LOC_X || mViewportY != World.WORLD_LOC_Y)
         {
            mMapCropBitmap.bitmapData = mEntireMap;
            mMapCropBitmap.x = -World.WORLD_LOC_X - WORLD_INSET / 2;
            mMapCropBitmap.y = -World.WORLD_LOC_Y - WORLD_INSET / 2;
            mMapViewport.draw(mMapCrop,null,null,null,mMapViewport.rect,false);
            mViewportX = World.WORLD_LOC_X;
            mViewportY = World.WORLD_LOC_Y;
            mViewportDirty = false;
            ++mViewportCopies;
         }
         queue(mMapViewport);
      }

      private static var mKeepIdentityFilters:Boolean = true;
      private static var mIdentityFilters:Array;

      // TweenMax leaves a zero-radius BlurFilter after its 10-second intro tween. It is
      // mathematically an identity but still forces Ruffle to render an offscreen layer.
      // Keep every nonzero blur and all other filters, preserving the original effects.
      private static function DropIdentityFilters() : void
      {
         if(mKeepIdentityFilters)
         {
            return;
         }
         var filters:Array = mScreen.filters;
         var kept:Array = [];
         var filter:*;
         for each(filter in filters)
         {
            if(!(filter is BlurFilter && filter.blurX == 0 && filter.blurY == 0))
            {
               kept.push(filter);
            }
         }
         if(kept.length != filters.length)
         {
            mIdentityFilters = filters;
            mScreen.filters = kept;
         }
      }

      public static function setIdentityFilterBypass(param1:Boolean) : Object
      {
         mKeepIdentityFilters = !param1;
         if(mKeepIdentityFilters && mScreen.filters.length == 0 && mIdentityFilters != null)
         {
            mScreen.filters = mIdentityFilters;
         }
         DropIdentityFilters();
         return renderInfo();
      }

      public static function flush() : void
      {
         DropIdentityFilters();
      }

      public static function renderInfo() : Object
      {
         var bounds:Rectangle = mScreen.getBounds(mScreen);
         var filterInfo:Array = [];
         var filter:*;
         for each(filter in mScreen.filters)
         {
            if(filter is BlurFilter)
            {
               filterInfo.push({type:"BlurFilter",blurX:filter.blurX,blurY:filter.blurY,quality:filter.quality});
            }
         }
         var childRows:Array = [];
         var rawBounds:Rectangle = new Rectangle(0,0,World.SCREEN_WIDTH,World.SCREEN_HEIGHT);
         for(var i:int = 0; i < mScreen.numChildren; ++i)
         {
            var child:DisplayObject = mScreen.getChildAt(i);
            var r:Rectangle = child.getBounds(mScreen);
            rawBounds = rawBounds.union(r);
            var row:Object = {index:i,name:child.name,bounds:[r.x,r.y,r.width,r.height],filters:child.filters.length};
            if(child is Bitmap && Bitmap(child).bitmapData != null) row.bitmap = [Bitmap(child).bitmapData.width,Bitmap(child).bitmapData.height];
            childRows.push(row);
         }
         return {cullBitmapQuads:mCullBitmapQuads,culledBitmapDraws:mCulledBitmapDraws,rawBounds:[rawBounds.x,rawBounds.y,rawBounds.width,rawBounds.height],childRows:childRows,boundsWidth:bounds.width,boundsHeight:bounds.height,mapWidth:mEntireMap.width,mapHeight:mEntireMap.height,viewportCopies:mViewportCopies,children:mScreen.numChildren,filters:mScreen.filters.length,filterInfo:filterInfo};
      }

      private static var mBackground:Shape;

      private static var mPool:Array = [];

      private static var mUsed:int = 0;

      private static var mWrappers:Array = [];

      private static var mWrappersUsed:int = 0;

      private static const IDENTITY:ColorTransform = new ColorTransform();

      private static function InitScreen() : void
      {
         mScreen.mouseEnabled = false;
         mScreen.mouseChildren = false;
         // Clip to the screen like the old 800x600 bitmap. Without it the sprite's bounds include the whole
         // 4640x2390 world map, and the filters tweened onto mBackgroundBitmap would be rendered at that size.
         mScreen.scrollRect = new Rectangle(0,0,World.SCREEN_WIDTH,World.SCREEN_HEIGHT);
         mBackground = new Shape();
         mBackground.graphics.beginFill(5341124,1);
         mBackground.graphics.drawRect(0,0,World.SCREEN_WIDTH,World.SCREEN_HEIGHT);
         mBackground.graphics.endFill();
         mScreen.addChild(mBackground);
      }

      // Start a new frame: the equivalent of the fillRect + full-screen map copy that began each frame.
      private static function BeginFrame() : void
      {
         var _loc1_:int = 0;
         while(mScreen.numChildren > 1)
         {
            mScreen.removeChildAt(mScreen.numChildren - 1);
         }
         _loc1_ = 0;
         while(_loc1_ < mUsed)
         {
            Bitmap(mPool[_loc1_]).bitmapData = null;
            _loc1_++;
         }
         _loc1_ = 0;
         while(_loc1_ < mWrappersUsed)
         {
            Sprite(mWrappers[_loc1_]).removeChildAt(0);
            _loc1_++;
         }
         mUsed = 0;
         mWrappersUsed = 0;
      }

      // Stand-in for mScreenBitmapData.draw(bitmapData,matrix,colorTransform,blendMode,null,smoothing).
      public static function queue(param1:BitmapData, param2:Matrix = null, param3:ColorTransform = null, param4:String = null, param5:Boolean = false) : void
      {
         if(mCullBitmapQuads && !bitmapOnScreen(param1,param2)) { ++mCulledBitmapDraws; return; }

         var _loc6_:Bitmap = null;
         if(mUsed < mPool.length)
         {
            _loc6_ = mPool[mUsed];
         }
         else
         {
            _loc6_ = new Bitmap();
            mPool.push(_loc6_);
         }
         mUsed++;
         _loc6_.bitmapData = param1;
         _loc6_.smoothing = param5;
         _loc6_.transform.matrix = param2 != null ? param2 : new Matrix();
         _loc6_.transform.colorTransform = param3 != null ? param3 : IDENTITY;
         _loc6_.blendMode = param4 != null ? param4 : BlendMode.NORMAL;
         mScreen.addChild(_loc6_);
      }

      // Stand-in for mScreenBitmapData.copyPixels(src,rect,new Point(x,y),null,null,true).
      public static function blit(param1:BitmapData, param2:Rectangle, param3:Number, param4:Number) : void
      {
         queue(param1,new Matrix(1,0,0,1,int(param3) - param2.x,int(param4) - param2.y));
      }

      // Stand-in for mScreenBitmapData.draw(displayObject,matrix). draw() ignores the object's own
      // transform, so the wrapper undoes it before applying the matrix.
      public static function queueObject(param1:DisplayObject, param2:Matrix = null) : void
      {
         var _loc3_:Sprite = null;
         var _loc4_:Matrix = null;
         if(mWrappersUsed < mWrappers.length)
         {
            _loc3_ = mWrappers[mWrappersUsed];
         }
         else
         {
            _loc3_ = new Sprite();
            mWrappers.push(_loc3_);
         }
         mWrappersUsed++;
         _loc4_ = param1.transform.matrix.clone();
         _loc4_.invert();
         if(param2 != null)
         {
            _loc4_.concat(param2);
         }
         _loc3_.transform.matrix = _loc4_;
         _loc3_.addChild(param1);
         mScreen.addChild(_loc3_);
      }
      // Exact broad-phase index for the same Circle.ContainsPoint predicate.
      // Circles use truncated integer deltas, hence the conservative 1-unit pad.
      private static var mPointGrid:Object;
      private static var mPointGridSource:Array;
      private static var mPointGridCount:int = -1;
      private static var mLastAvatarKey:String = "";
      private static var mLastAvatarX:Number;
      private static var mLastAvatarY:Number;

      private static function EnsurePointGrid() : void
      {
         if(mPointGridSource === mLandArray && mPointGridCount == mLandArray.length) return;
         mPointGridSource = mLandArray;
         mPointGridCount = mLandArray.length;
         mPointGrid = {};
         mLastAvatarKey = "";
         for each(var blob:Object in mLandArray)
         {
            var circle:Circle = blob.circle;
            var left:int = Math.floor((circle.x - circle.r - 1) / 256);
            var right:int = Math.floor((circle.x + circle.r + 1) / 256);
            var top:int = Math.floor((circle.y - circle.r - 1) / 256);
            var bottom:int = Math.floor((circle.y + circle.r + 1) / 256);
            for(var gx:int = left; gx <= right; ++gx)
               for(var gy:int = top; gy <= bottom; ++gy)
               {
                  var key:String = gx + ":" + gy;
                  if(mPointGrid[key] == null) mPointGrid[key] = [];
                  mPointGrid[key].push(circle);
               }
         }
      }

      public static function pointOnLandFast(px:int, py:int) : Boolean
      {
         // Keep original integer-overflow behavior for extraordinary coordinates.
         if(Math.abs(px) > 8192 || Math.abs(py) > 8192) return TestCollision.PointOnLand(px,py);
         EnsurePointGrid();
         var candidates:Array = mPointGrid[Math.floor(px / 256) + ":" + Math.floor(py / 256)] as Array;
         if(candidates != null)
            for each(var circle:Circle in candidates)
               if(circle.ContainsPoint(px,py)) return true;
         return false;
      }

      public static function nextAvatarStep(dx:int, dy:int, px:int, py:int, speed:int) : Vector2D
      {
         // The original result is zero even outside land; avoid its 73-angle scan.
         if(dx == px && dy == py) return new Vector2D(0,0);
         EnsurePointGrid();
         var step:Vector2D = new Vector2D(dx - px,dy - py);
         step.Truncate(speed);
         if(pointOnLandFast(px + step.x,py + step.y)) return step;
         var key:String = dx + ":" + dy + ":" + px + ":" + py + ":" + speed;
         if(key == mLastAvatarKey) return new Vector2D(mLastAvatarX,mLastAvatarY);
         // Preserve the original compiled movement fallback, including shore rules.
         step = TestCollision.NextStep(dx,dy,px,py,speed);
         mLastAvatarKey = key; mLastAvatarX = step.x; mLastAvatarY = step.y;
         return step;
      }

      private static var mCullBitmapQuads:Boolean = true;
      private static var mCulledBitmapDraws:int = 0;
      public static function setBitmapCull(enabled:Boolean) : Object
      {
         mCullBitmapQuads = enabled;
         return renderInfo();
      }
      private static function bitmapOnScreen(data:BitmapData, m:Matrix) : Boolean
      {
         if(m == null) return true;
         var x0:Number = m.tx;
         var y0:Number = m.ty;
         var x1:Number = x0 + data.width*m.a;
         var y1:Number = y0 + data.width*m.b;
         var x2:Number = x0 + data.height*m.c;
         var y2:Number = y0 + data.height*m.d;
         var x3:Number = x1 + data.height*m.c;
         var y3:Number = y1 + data.height*m.d;
         return Math.max(x0,x1,x2,x3) >= -1 && Math.max(y0,y1,y2,y3) >= -1 && Math.min(x0,x1,x2,x3) <= World.SCREEN_WIDTH + 1 && Math.min(y0,y1,y2,y3) <= World.SCREEN_HEIGHT + 1;
      }

   }
}
