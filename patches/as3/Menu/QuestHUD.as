package Menu
{
   import Art.LoadArt;
   import Drawing.BitmapFrame;
   import Geom.Vector2D;
   import Land.Land;
   import MapItems.GenericItem;
   import MapItems.Items;
   import World.World;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;

   public class QuestHUD extends MovieClip
   {

      public static var mFocusItem:GenericItem;

      private var mQuestArray:Array;

      private var mIconArray:Array;

      private const screenRect:Rectangle = new Rectangle(0,24,World.SCREEN_WIDTH,World.SCREEN_HEIGHT - 24);

      private var arrowPos:Number = 0;

      private var mUp:Boolean = true;

      public function QuestHUD()
      {
         super();
         this.mIconArray = new Array();
      }

      public function onUpdate(param1:Event = null) : void
      {
         var _loc2_:int = 0;
         var _loc3_:Matrix = null;
         var _loc4_:BitmapFrame = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:ColorTransform = null;
         var _loc8_:Vector2D = null;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         this.mQuestArray = Items.GetQuests();
         _loc2_ = 0;
         while(_loc2_ < this.mQuestArray.length)
         {
            _loc4_ = LoadArt.mHUDArt.getFrame(this.mQuestArray[_loc2_].frame + 11 * this.mQuestArray[_loc2_].rot);
            _loc5_ = this.mQuestArray[_loc2_].x + _loc4_.hotspotX;
            _loc6_ = this.mQuestArray[_loc2_].y + _loc4_.hotspotY;
            _loc3_ = new Matrix();
            _loc3_.translate(_loc5_,_loc6_);
            _loc7_ = new ColorTransform();
            _loc7_.alphaMultiplier = this.mQuestArray[_loc2_].alpha;
            Land.queue(_loc4_.bitmapData,_loc3_,_loc7_,null,true);
            _loc2_++;
         }
         if(mFocusItem)
         {
            _loc8_ = new Vector2D(mFocusItem.x - World.WORLD_LOC_X - 320,mFocusItem.y / 2 - World.WORLD_LOC_Y - 240);
            if(!this.screenRect.contains(_loc8_.x + 320,_loc8_.y + 240))
            {
               if(Math.abs(_loc8_.x) / Math.abs(_loc8_.y) > this.screenRect.width / this.screenRect.height)
               {
                  if(_loc8_.x > 0)
                  {
                     _loc10_ = this.screenRect.width / 2;
                  }
                  else
                  {
                     _loc10_ = -this.screenRect.width / 2;
                  }
                  _loc9_ = _loc8_.y * (_loc10_ / _loc8_.x);
               }
               else
               {
                  if(_loc8_.y > 0)
                  {
                     _loc9_ = this.screenRect.height / 2;
                  }
                  else
                  {
                     _loc9_ = -this.screenRect.height / 2;
                  }
                  _loc10_ = _loc8_.x * (_loc9_ / _loc8_.y);
               }
               _loc10_ += this.screenRect.width / 2 + this.screenRect.x;
               _loc9_ += this.screenRect.height / 2 + this.screenRect.y;
               if(_loc10_ == this.screenRect.width + this.screenRect.x)
               {
                  _loc11_ = 0;
                  if(_loc9_ < this.screenRect.y + 48)
                  {
                     _loc9_ = this.screenRect.y + 48;
                  }
                  if(_loc9_ > this.screenRect.y + this.screenRect.height - 48)
                  {
                     _loc9_ = this.screenRect.y + this.screenRect.height - 48;
                  }
               }
               else if(_loc9_ == this.screenRect.height + this.screenRect.y)
               {
                  _loc11_ = 1;
                  if(_loc10_ < this.screenRect.x + 48)
                  {
                     _loc10_ = this.screenRect.x + 48;
                  }
                  if(_loc10_ > this.screenRect.x + this.screenRect.width - 48)
                  {
                     _loc10_ = this.screenRect.x + this.screenRect.width - 48;
                  }
               }
               else if(_loc9_ == this.screenRect.y)
               {
                  _loc11_ = 3;
                  if(_loc10_ < this.screenRect.x + 48)
                  {
                     _loc10_ = this.screenRect.x + 48;
                  }
                  if(_loc10_ > this.screenRect.x + this.screenRect.width - 48)
                  {
                     _loc10_ = this.screenRect.x + this.screenRect.width - 48;
                  }
               }
               else if(_loc10_ == this.screenRect.x)
               {
                  _loc11_ = 2;
                  if(_loc9_ < this.screenRect.y + 48)
                  {
                     _loc9_ = this.screenRect.y + 48;
                  }
                  if(_loc9_ > this.screenRect.y + this.screenRect.height - 48)
                  {
                     _loc9_ = this.screenRect.y + this.screenRect.height - 48;
                  }
               }
               _loc4_ = LoadArt.mHUDArt.getFrame(4 + 11 * _loc11_);
               _loc5_ = _loc10_ + _loc4_.hotspotX;
               _loc6_ = _loc9_ + _loc4_.hotspotY;
            }
            else
            {
               if(this.mUp)
               {
                  ++this.arrowPos;
                  if(this.arrowPos > 10)
                  {
                     this.mUp = false;
                  }
               }
               else
               {
                  --this.arrowPos;
                  if(this.arrowPos < 0)
                  {
                     this.mUp = true;
                  }
               }
               _loc4_ = LoadArt.mHUDArt.getFrame(45);
               _loc5_ = 320 + _loc8_.x + _loc4_.hotspotX;
               _loc6_ = 240 + _loc8_.y + _loc4_.hotspotY - 50 - this.arrowPos;
            }
            _loc3_ = new Matrix();
            _loc3_.translate(_loc5_,_loc6_);
            Land.queue(_loc4_.bitmapData,_loc3_,null,null,true);
         }
      }
   }
}
