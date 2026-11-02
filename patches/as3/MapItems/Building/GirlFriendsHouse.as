package MapItems.Building
{
   import Art.LoadArt;
   import Geom.Circle;
   import Land.Land;
   import MapItems.GenericItem;
   import MapItems.GirlBunny.GirlBunny;
   import MapItems.GirlBunny.GirlFriendBunny;
   import Missions.Missions;
   import World.World;
   import flash.display.MovieClip;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;

   public class GirlFriendsHouse extends GenericItem
   {

      private var mWoodText:MovieClip;

      public var mBoundry:Circle;

      public function GirlFriendsHouse(param1:int, param2:int)
      {
         super();
         this.mWoodText = new WoodText();
         this.mBoundry = new Circle(param1,param2,800);
         this.init(param1,param2,LoadArt.mGirlFriendsHouse,new Circle(param1,param2,100),this.mBoundry,0);
      }

      override public function initStateMachine() : void
      {
         new GirlBunny(this.x - 100,this.y + 100,this);
         new GirlBunny(this.x,this.y + 100,this);
         new GirlBunny(this.x + 100,this.y + 100,this);
         new GirlFriendBunny(this.x,this.y + 200,this);
      }

      override public function draw() : void
      {
         var _loc2_:Matrix = null;
         if(mStateMachine)
         {
            mStateMachine.Update();
         }
         drawx = x - World.WORLD_LOC_X;
         drawy = y / 2 - World.WORLD_LOC_Y;
         var _loc1_:Rectangle = new Rectangle(0,0,World.SCREEN_WIDTH,World.SCREEN_HEIGHT);
         itemRect = new Rectangle(drawx + mArt.hotspotX,drawy + mArt.hotspotY,mArt.mRect.width,mArt.mRect.height);
         if(_loc1_.intersects(itemRect))
         {
            Land.blit(mArt.bitmapData,mArt.mRect,drawx + mArt.hotspotX,drawy + mArt.hotspotY);
            this.mWoodText.mText.text = String(Missions.GetWood());
            _loc2_ = new Matrix();
            _loc2_.translate(drawx - 147,drawy - 33);
            Land.queueObject(this.mWoodText,_loc2_);
         }
      }
   }
}
