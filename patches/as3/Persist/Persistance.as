package Persist
{
   import MapItems.Animals.GenericAnimal;
   import MapItems.Animals.MonsterItem;
   import MapItems.GenericItem;
   import MapItems.GirlBunny.MissionStatic;
   import MapItems.StoreItems.PlacementItem;
   import MapItems.StoreItems.StoreItem;
   import MapItems.StoreItems.StoreItemsList;
   import Switches.Switch;
   import World.World;
   import com.adobe.crypto.MD5;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.net.SharedObject;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.net.URLRequestMethod;
   import flash.net.URLVariables;

   public class Persistance
   {

      private static var sharedObject:SharedObject;

      private static var purchaseURL:URLRequest = new URLRequest("http://localhost/phpbunnything/purchase.php");

      private static var updateURL:URLRequest = new URLRequest("http://localhost/phpbunnything/updateitem.php");

      private static var switchURL:URLRequest = new URLRequest("http://localhost/phpbunnything/updateswitch.php");

      private static var sellURL:URLRequest = new URLRequest("http://localhost/phpbunnything/sell.php");

      private static var persistantItems:Array = new Array();

      private static var objectId:int = 0;

      private static var mSetupDone:Boolean = false;

      public function Persistance()
      {
         super();
      }

      public static function newGame(param1:int) : SharedObject
      {
         sharedObject = getObject(param1);
         sharedObject.data["init"] = true;
         sharedObject.flush();
         return sharedObject;
      }

      public static function deleteGame(param1:int) : SharedObject
      {
         sharedObject = getObject(param1);
         sharedObject.data["init"] = false;
         sharedObject.flush();
         return sharedObject;
      }

      public static function continueGame(param1:int) : SharedObject
      {
         return getObject(param1);
      }

      public static function getObject(param1:int) : SharedObject
      {
         var object:SharedObject = SharedObject.getLocal("bunni-fast-slot-v1-" + param1,"/");
         if(!object.data.hasOwnProperty("init"))
         {
            var legacy:SharedObject = SharedObject.getLocal("slot" + param1);
            object.data["init"] = legacy.data["init"] == true;
            object.flush();
         }
         return object;
      }

      public static function gift() : void
      {
         var _loc1_:PlacementItem = StoreItemsList.MakePlacementItem("White Flower Tree",World.mAvatar.x,World.mAvatar.y);
         Persistance.CreateObject("White Flower Tree",null,_loc1_,null,true);
      }

      public static function LogIn() : void
      {
      }

      public static function Achivment(param1:String) : void
      {
         var _loc2_:URLVariables = null;
         var _loc3_:URLLoader = null;
         sharedObject["switch"][param1] = 1;
      }

      public static function OpenSingleBridge(param1:String) : *
      {
         var _loc2_:URLVariables = null;
         var _loc3_:URLLoader = null;
         sharedObject["switch"][param1] = 1;
      }

      private static function SetUpBridges(param1:String) : void
      {
         var _loc2_:int = 0;
         var _loc4_:Array = null;
         var _loc5_:Array = null;
         var _loc6_:Array = null;
         var _loc7_:String = null;
         var _loc8_:Boolean = false;
         var _loc9_:URLVariables = null;
         var _loc10_:URLLoader = null;
         var _loc3_:Array = new Array();
         if(param1 != "")
         {
            trace("WE HAVE BRIDGE DATA",param1);
            _loc4_ = param1.split("-");
            _loc5_ = new Array();
            _loc2_ = 0;
            while(_loc2_ < _loc4_.length)
            {
               _loc6_ = _loc4_[_loc2_].split(",");
               _loc7_ = _loc6_[0];
               _loc8_ = int(_loc6_[1]) == 1;
               trace("bridgeName",_loc7_);
               trace("isOpen",_loc8_);
               if(_loc7_ == "holy_statue" || _loc7_ == "three_plums" || _loc7_ == "gem_store" || _loc7_ == "peach_dance")
               {
                  trace("------ PERSISTENT QUEST --------");
                  trace("isOpen",_loc8_);
                  if(_loc8_)
                  {
                     if(_loc7_ == "peach_dance")
                     {
                        MissionStatic.mPaidGems = true;
                        _loc5_.push("peach_quest_5");
                     }
                     else
                     {
                        _loc5_.push(_loc7_);
                     }
                  }
               }
               else if(_loc8_ != Switch.IsOpen(_loc7_))
               {
                  if(_loc8_)
                  {
                     Switch.DrawBridge(_loc7_);
                  }
                  else
                  {
                     _loc3_.push(_loc7_);
                  }
               }
               _loc2_++;
            }
         }
         else
         {
            if(Switch.IsOpen("firstbridge"))
            {
               _loc3_.push("firstbridge");
            }
            if(Switch.IsOpen("secondbridge"))
            {
               _loc3_.push("secondbridge");
            }
            if(Switch.IsOpen("peteisle"))
            {
               _loc3_.push("peteisle");
            }
            if(Switch.IsOpen("piratecove"))
            {
               _loc3_.push("piratecove");
            }
            if(Switch.IsOpen("weddingisle"))
            {
               _loc3_.push("weddingisle");
            }
            if(Switch.IsOpen("monsterisle"))
            {
               _loc3_.push("monsterisle");
            }
         }
         if(_loc3_.length > 0)
         {
            _loc9_ = new URLVariables();
            _loc10_ = new URLLoader();
            _loc10_.addEventListener(Event.COMPLETE,placeSuccessful);
            _loc10_.addEventListener(IOErrorEvent.IO_ERROR,loadPageError);
            _loc9_.user_id = Bunni.uID;
            _loc2_ = 0;
            while(_loc2_ < _loc3_.length)
            {
               _loc9_[_loc3_[_loc2_]] = 1;
               _loc2_++;
            }
            _loc9_.code = MD5.hash(Bunni.uID + "76afb0");
            switchURL.method = URLRequestMethod.POST;
            switchURL.data = _loc9_;
            _loc10_.load(switchURL);
         }
         mSetupDone = true;
      }

      public static function SetUpObjects(param1:String) : *
      {
         var _loc2_:int = 0;
         var _loc5_:Array = null;
         var _loc6_:int = 0;
         var _loc7_:String = null;
         var _loc8_:Boolean = false;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:PlacementItem = null;
         var _loc12_:GenericItem = null;
         var _loc13_:PersistObject = null;
         var _loc14_:GenericAnimal = null;
         var _loc3_:Array = param1.split(":");
         var _loc4_:Array = _loc3_[0].split("-");
         _loc2_ = 0;
         while(_loc2_ < _loc4_.length)
         {
            _loc5_ = _loc4_[_loc2_].split(",");
            _loc6_ = int(_loc5_[0]);
            _loc7_ = convertName(_loc5_[1]);
            _loc8_ = int(_loc5_[2]) == 1;
            _loc9_ = int(_loc5_[3]);
            _loc10_ = int(_loc5_[4]);
            if(_loc8_)
            {
               if(_loc7_ == "Pirate" || _loc7_ == "Monster")
               {
                  _loc14_ = StoreItemsList.MakeItem(_loc7_,World.mAvatar.x,World.mAvatar.y);
                  _loc14_.FollowAvatar(World.mAvatar);
                  if(_loc14_ is MonsterItem)
                  {
                     MonsterItem(_loc14_).mTame = true;
                  }
                  _loc12_ = _loc14_;
               }
               else
               {
                  _loc11_ = StoreItemsList.MakePlacementItem(_loc7_,_loc9_,_loc10_);
               }
            }
            else
            {
               _loc12_ = StoreItemsList.MakeItem(_loc7_,_loc9_,_loc10_);
            }
            _loc13_ = new PersistObject(objectId,_loc11_,_loc12_);
            trace("HEY LOOKS LIKE WE ARE SETTING THE ID HERE",_loc6_);
            _loc13_.mDatabaseID = _loc6_;
            persistantItems.push(_loc13_);
            ++objectId;
            _loc2_++;
         }
      }

      public static function PickUp(param1:String, param2:StoreItem, param3:GenericItem, param4:PlacementItem) : void
      {
         var _loc5_:PersistObject = null;
         if(checkName(param1))
         {
            _loc5_ = getObjectFromStore(param2);
            if(_loc5_)
            {
               _loc5_.mItem = param3;
               _loc5_.mPlacement = param4;
            }
         }
      }

      public static function SellAnimal(param1:GenericItem) : void
      {
         trace("trying to sell an animale");
         var _loc2_:PersistObject = getObjectFromItemAndRemove(param1);
         if(_loc2_)
         {
            Sell(_loc2_);
         }
         else
         {
            trace("persistant item not found");
         }
      }

      public static function SellObject(param1:PlacementItem) : void
      {
         var _loc2_:PersistObject = getObjectFromPlacementAndRemove(param1);
         if(_loc2_)
         {
            Sell(_loc2_);
         }
      }

      private static function Sell(param1:PersistObject) : void
      {
         var _loc2_:URLVariables = null;
         var _loc3_:URLLoader = null;
         if(param1)
         {
            trace("we are SELLING OBJECT",param1.mID,param1);
            _loc2_ = new URLVariables();
            _loc3_ = new URLLoader();
            _loc3_.addEventListener(Event.COMPLETE,sellSuccessful);
            _loc3_.addEventListener(IOErrorEvent.IO_ERROR,loadPageError);
            _loc2_.item_id = param1.mDatabaseID;
            _loc2_.user_id = Bunni.uID;
            trace("we have th id and stuff",param1.mDatabaseID);
            _loc2_.code = MD5.hash(Bunni.uID + "j4kf9h" + param1.mDatabaseID);
            sellURL.method = URLRequestMethod.POST;
            sellURL.data = _loc2_;
            _loc3_.load(sellURL);
         }
      }

      private static function sellSuccessful(param1:Event) : void
      {
         var _loc2_:URLVariables = new URLVariables(param1.target.data);
         trace("SELL RESULT",_loc2_);
         if(_loc2_.success == "true")
         {
         }
      }

      public static function CreateObject(param1:String, param2:GenericItem, param3:PlacementItem, param4:StoreItem = null, param5:Boolean = false) : void
      {
         var _loc6_:PersistObject = null;
         var _loc7_:URLVariables = null;
         var _loc8_:URLLoader = null;
         var _loc9_:String = null;
         if(checkName(param1))
         {
            trace("OUR OBJECT WAS CREATED WITH AN ID",objectId);
            _loc6_ = new PersistObject(objectId,param3,param2);
            persistantItems.push(_loc6_);
            if(param4)
            {
               _loc6_.SetStore(param4);
            }
            _loc7_ = new URLVariables();
            _loc8_ = new URLLoader();
            _loc8_.addEventListener(Event.COMPLETE,purchaseSuccessful);
            _loc8_.addEventListener(IOErrorEvent.IO_ERROR,loadPageError);
            _loc9_ = SingleLower(param1);
            _loc7_.item_tag = _loc9_;
            _loc7_.user_id = Bunni.uID;
            _loc7_.obj_id = objectId;
            if(param5)
            {
               _loc7_.gift = "true";
            }
            _loc7_.code = MD5.hash(Bunni.uID + "e0c41b" + _loc9_);
            trace("pageVars.item_tag",_loc7_.item_tag);
            trace("pageVars.user_id",_loc7_.user_id);
            trace("pageVars.obj_id",_loc7_.obj_id);
            trace("before code",Bunni.uID + "e0c41b" + _loc9_);
            trace("pageVars.code",_loc7_.code);
            purchaseURL.method = URLRequestMethod.POST;
            purchaseURL.data = _loc7_;
            _loc8_.load(purchaseURL);
            ++objectId;
         }
      }

      private static function purchaseSuccessful(param1:Event) : void
      {
         var _loc2_:URLVariables = new URLVariables(param1.target.data);
         var _loc3_:PersistObject = getObjectFromID(_loc2_.obj_id);
         if(_loc2_.success == "true")
         {
            _loc3_.SetDatabaseID(_loc2_.item_id);
            trace("APPEARS TO HAVE WORKD");
            trace("ID" + _loc2_.item_id);
            trace("GEMS" + _loc2_.gems);
         }
         else
         {
            trace("SOUNDS LIKE WE DIDNT HAVE ENOUGH MONEY OR IT WAS FREE" + _loc2_.problem);
         }
      }

      public static function PlaceObject(param1:GenericItem, param2:PlacementItem, param3:int, param4:int) : void
      {
         var _loc6_:URLVariables = null;
         var _loc7_:URLLoader = null;
         var _loc5_:PersistObject = getObjectFromPlacement(param2);
         if(_loc5_)
         {
            trace("we are placing",_loc5_.mID,_loc5_);
            _loc5_.SetItem(param1);
            _loc6_ = new URLVariables();
            _loc7_ = new URLLoader();
            _loc7_.addEventListener(Event.COMPLETE,purchaseSuccessful);
            _loc7_.addEventListener(IOErrorEvent.IO_ERROR,loadPageError);
            _loc6_.item_id = _loc5_.mDatabaseID;
            _loc6_.user_id = Bunni.uID;
            _loc6_.store = 0;
            _loc6_.locx = param3;
            _loc6_.locy = param4;
            _loc6_.code = MD5.hash(Bunni.uID + "7ae2fc" + _loc5_.mDatabaseID + _loc6_.store + param3 + param4);
            updateURL.method = URLRequestMethod.POST;
            updateURL.data = _loc6_;
            _loc7_.load(updateURL);
         }
      }

      private static function placeSuccessful(param1:Event) : void
      {
         var _loc2_:URLVariables = new URLVariables(param1.target.data);
      }

      public static function DestroyObject(param1:GenericItem, param2:StoreItem) : void
      {
         var _loc4_:URLVariables = null;
         var _loc5_:URLLoader = null;
         var _loc3_:PersistObject = getObjectFromItem(param1);
         if(_loc3_)
         {
            _loc3_.SetStore(param2);
            _loc4_ = new URLVariables();
            _loc5_ = new URLLoader();
            _loc5_.addEventListener(Event.COMPLETE,purchaseSuccessful);
            _loc5_.addEventListener(IOErrorEvent.IO_ERROR,loadPageError);
            _loc4_.item_id = _loc3_.mDatabaseID;
            _loc4_.user_id = Bunni.uID;
            _loc4_.store = 1;
            _loc4_.locx = 0;
            _loc4_.locy = 0;
            _loc4_.code = MD5.hash(Bunni.uID + "7ae2fc" + _loc3_.mDatabaseID + _loc4_.store + _loc4_.locx + _loc4_.locy);
            updateURL.method = URLRequestMethod.POST;
            updateURL.data = _loc4_;
            _loc5_.load(updateURL);
         }
      }

      private static function loadPageError(param1:IOErrorEvent) : void
      {
         trace("server error");
      }

      private static function getObjectFromID(param1:int) : PersistObject
      {
         var _loc2_:int = 0;
         _loc2_ = 0;
         while(_loc2_ < persistantItems.length)
         {
            if(persistantItems[_loc2_].mID == param1)
            {
               return persistantItems[_loc2_];
            }
            _loc2_++;
         }
         return null;
      }

      private static function getObjectFromPlacement(param1:PlacementItem) : PersistObject
      {
         var _loc2_:int = 0;
         _loc2_ = 0;
         while(_loc2_ < persistantItems.length)
         {
            if(persistantItems[_loc2_].mPlacement == param1)
            {
               return persistantItems[_loc2_];
            }
            _loc2_++;
         }
         return null;
      }

      private static function getObjectFromPlacementAndRemove(param1:PlacementItem) : PersistObject
      {
         var _loc2_:int = 0;
         var _loc3_:PersistObject = null;
         _loc2_ = 0;
         while(_loc2_ < persistantItems.length)
         {
            if(persistantItems[_loc2_].mPlacement == param1)
            {
               _loc3_ = persistantItems[_loc2_];
               persistantItems.splice(_loc2_,1);
               return _loc3_;
            }
            _loc2_++;
         }
         return null;
      }

      private static function getObjectFromItemAndRemove(param1:GenericItem) : PersistObject
      {
         var _loc2_:int = 0;
         var _loc3_:PersistObject = null;
         _loc2_ = 0;
         while(_loc2_ < persistantItems.length)
         {
            if(persistantItems[_loc2_].mItem == param1)
            {
               _loc3_ = persistantItems[_loc2_];
               persistantItems.splice(_loc2_,1);
               return _loc3_;
            }
            _loc2_++;
         }
         return null;
      }

      private static function getObjectFromItem(param1:GenericItem) : PersistObject
      {
         var _loc2_:int = 0;
         _loc2_ = 0;
         while(_loc2_ < persistantItems.length)
         {
            if(persistantItems[_loc2_].mItem == param1)
            {
               return persistantItems[_loc2_];
            }
            _loc2_++;
         }
         return null;
      }

      private static function getObjectFromStore(param1:StoreItem) : PersistObject
      {
         var _loc2_:int = 0;
         _loc2_ = 0;
         while(_loc2_ < persistantItems.length)
         {
            if(persistantItems[_loc2_].mStore == param1)
            {
               return persistantItems[_loc2_];
            }
            _loc2_++;
         }
         return null;
      }

      private static function convertName(param1:String) : String
      {
         var _loc2_:int = 0;
         var _loc3_:Array = ["Legendary Plum Tree","Legendary Mill","Legendary Mine","White Flower Tree","Pink Flower Tree","Holy Statue","Gem Statue","Pirate","Monster","Gem Store"];
         _loc2_ = 0;
         while(_loc2_ < _loc3_.length)
         {
            if(param1 == SingleLower(_loc3_[_loc2_]))
            {
               return _loc3_[_loc2_];
            }
            _loc2_++;
         }
         return "";
      }

      public static function checkName(param1:String) : Boolean
      {
         if(param1 == "Legendary Plum Tree" || param1 == "Legendary Mill" || param1 == "Legendary Mine" || param1 == "White Flower Tree" || param1 == "Pink Flower Tree" || param1 == "Holy Statue" || param1 == "Gem Statue" || param1 == "Pirate" || param1 == "Monster" || param1 == "Gem Store")
         {
            return true;
         }
         return false;
      }

      private static function SingleLower(param1:String) : String
      {
         param1 = removeExtraWhitespace(param1);
         return param1.toLowerCase();
      }

      private static function removeExtraWhitespace(param1:String) : String
      {
         if(param1 == null)
         {
            return "";
         }
         return param1.replace(/\s+/g,"");
      }
   }
}
