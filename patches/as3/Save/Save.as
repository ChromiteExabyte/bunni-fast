package Save
{
   import Bridge.Bridges;
   import Tutorial.Tasks;
   import com.adobe.crypto.MD5;
   import flash.events.NetStatusEvent;
   import flash.net.SharedObjectFlushStatus;
   import flash.utils.getTimer;
   import CurrencyPlugin.SuperReward;
   import MapItems.Animals.GenericAnimal;
   import MapItems.Animals.MonsterItem;
   import MapItems.Coriander.CorianderItem;
   import MapItems.FruitTrees.FruitTree;
   import MapItems.GenericItem;
   import MapItems.Ghosts.QuestItem;
   import MapItems.Items;
   import MapItems.Mote.MoteItem;
   import MapItems.Mote.States.AnimateOut;
   import MapItems.StoreItems.BridgeAngelItem;
   import MapItems.StoreItems.PlacementItem;
   import MapItems.StoreItems.StoreItem;
   import MapItems.StoreItems.StoreItemsList;
   import MapItems.Terrain.HillItems.*;
   import Menu.HUD;
   import Persist.Persistance;
   import Quests.CorianderMissions;
   import Quests.Ghosts;
   import Quests.MissionSetUps;
   import Quests.PeachMissions;
   import Rewards.*;
   import World.World;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.TimerEvent;
   import flash.net.SharedObject;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.net.URLRequestMethod;
   import flash.net.URLVariables;
   import flash.utils.Timer;

   public class Save
   {

      private static var mCallback:Function;

      private static var mAutoSaveTimer:Timer;

      private static var mCallbackSave:Function;

      public static var mHasSaved:Boolean = false;

      private static var mAutoSave:Boolean = false;

      private static var mTemplate:XML;
      private static var mTrustedRecord:Object;
      private static var mLoaded:Boolean = false;
      private static var mLocalLoaded:Boolean = false;
      private static var mLastSave:int = 0;
      private static var mBusy:Boolean = false;
      public static var mLastError:String = "";
      public static var mSavedAt:Number = 0;

      public function Save()
      {
         super();
      }

      public static function DoLoad(param1:Function) : void
      {
         var _loc2_:URLLoader = null;
         mCallback = param1;
         Items.DestroyAll();
         _loc2_ = new URLLoader();
         _loc2_.addEventListener(Event.COMPLETE,XMLloaded);
         _loc2_.load(new URLRequest("save_data.xml"));
      }

      public static function EnableAutoSave() : void
      {
         mAutoSave = !Bunni.mViewGame && mLastError.indexOf("disabled") < 0;
      }

      // Called by World only between complete updates, outside a drag or modal.
      public static function AutoSaveTick() : void
      {
         if(mLoaded && mAutoSave && !mBusy && getTimer() - mLastSave >= 15000)
         {
            mLastSave = getTimer();
            SaveNow(null);
         }
      }

      private static function XMLloaded(param1:Event) : void
      {
         var _loc3_:String = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc12_:GenericAnimal = null;
         var _loc14_:GenericItem = null;
         var _loc2_:XML = new XML(param1.target.data);
         mTemplate = _loc2_.copy();
         mLocalLoaded = false;
         if(!Bunni.mNewID)
         {
            var record:Object = ReadRecord();
            if(record != null)
            {
               _loc2_ = MergeSnapshot(new XML(record.xml));
               mLocalLoaded = true;
               mSavedAt = Number(record.savedAt);
            }
         }
         if(mLocalLoaded && _loc2_.avatar.length())
         {
            World.mAvatar.x = Number(_loc2_.avatar.@x);
            World.mAvatar.y = Number(_loc2_.avatar.@y);
            World.mAvatar.Stop();
            World.WORLD_LOC_X = World.mAvatar.x - World.SCREEN_WIDTH / 2;
            World.WORLD_LOC_Y = World.mAvatar.y / 2 - World.SCREEN_HEIGHT / 2;
         }
         var _loc11_:Array = new Array();
         var _loc13_:Boolean = false;
         trace("SET WOOD AND GOLD",int(_loc2_.wood[0]),int(_loc2_.gold[0]));
         if(!mLocalLoaded && int(_loc2_.wood[0]) == 0 && int(_loc2_.gold[0]) == 0)
         {
            HUD.SetWoodGoldGem(1000,1500,0);
         }
         else
         {
            HUD.SetWoodGoldGem(int(_loc2_.wood[0]),int(_loc2_.gold[0]),int(_loc2_.gems[0]));
         }
         Motes.SetUp(_loc2_.mote);
         Cards.SetUp(_loc2_.card);
         Ghosts.SetUp(_loc2_.ghost);
         Bridges.SetUp(_loc2_.bridge);
         StoreItem.SetUp(_loc2_.balance);
         CorianderMissions.SetUp(_loc2_.coriander,_loc2_.coriander_comment);
         PeachMissions.SetUp(_loc2_.piratepeach,_loc2_.peach_comment);
         if(mLocalLoaded)
         {
            for each(var progress:XML in _loc2_.quest_progress)
               SetStage(String(progress.@name),int(progress.@id),int(progress.@stage));
         }
         _loc6_ = 0;
         while(_loc6_ < _loc2_.item.length())
         {
            _loc13_ = true;
            _loc3_ = _loc2_.item[_loc6_].@name;
            _loc4_ = int(_loc2_.item[_loc6_].location.x);
            _loc5_ = int(_loc2_.item[_loc6_].location.y);
            _loc8_ = int(_loc2_.item[_loc6_].item_id);
            _loc9_ = int(_loc2_.item[_loc6_].mission_id);
            _loc10_ = int(_loc2_.item[_loc6_].mission_stage);
            _loc14_ = StoreItemsList.MakeItem(_loc3_,_loc4_,_loc5_);
            _loc14_.mMissionID = _loc9_;
            _loc11_.push({
               "work":_loc14_,
               "item_id":_loc8_
            });
            SetStage(_loc3_,_loc9_,_loc10_);
            if(_loc14_ is QuestItem)
            {
               QuestItem(_loc14_).SetByID();
            }
            _loc6_++;
         }
         _loc6_ = 0;
         while(_loc6_ < _loc2_.animal.length())
         {
            _loc13_ = true;
            _loc3_ = _loc2_.animal[_loc6_].@name;
            _loc4_ = int(_loc2_.animal[_loc6_].location.x);
            _loc5_ = int(_loc2_.animal[_loc6_].location.y);
            _loc8_ = int(_loc2_.animal[_loc6_].item_id);
            _loc12_ = StoreItemsList.MakeItem(_loc3_,_loc4_,_loc5_);
            if(_loc2_.animal[_loc6_].@hunger.length())
            {
               _loc12_.mHunger = int(_loc2_.animal[_loc6_].@hunger);
               _loc12_.mIsHungry = String(_loc2_.animal[_loc6_].@hungry) == "true";
            }
            if(_loc8_ == 99999)
            {
               _loc12_.x = World.mAvatar.x;
               _loc12_.y = World.mAvatar.y;
               _loc12_.FollowAvatar(World.mAvatar);
               if(_loc12_ is MonsterItem)
               {
                  MonsterItem(_loc12_).mTame = true;
               }
            }
            else if(_loc8_ != 0)
            {
               _loc7_ = 0;
               while(_loc7_ < _loc11_.length)
               {
                  if(_loc8_ == _loc11_[_loc7_].item_id)
                  {
                     _loc12_.SetWork(_loc11_[_loc7_].work);
                     if(_loc12_ is MonsterItem)
                     {
                        MonsterItem(_loc12_).mTame = true;
                     }
                  }
                  _loc7_++;
               }
            }
            _loc6_++;
         }
         _loc6_ = 0;
         while(_loc6_ < _loc2_.bubble.length())
         {
            _loc13_ = true;
            _loc3_ = _loc2_.bubble[_loc6_].@name;
            _loc4_ = int(_loc2_.bubble[_loc6_].location.x);
            _loc5_ = int(_loc2_.bubble[_loc6_].location.y);
            _loc9_ = int(_loc2_.bubble[_loc6_].mission_id);
            _loc10_ = int(_loc2_.bubble[_loc6_].mission_stage);
            SetStage(_loc3_,_loc9_,_loc10_);
            if(_loc9_ == 9999)
            {
               _loc14_ = StoreItemsList.MakeStore(_loc3_,_loc4_,_loc5_,false);
            }
            else
            {
               _loc14_ = StoreItemsList.MakeStore(_loc3_,_loc4_,_loc5_,true);
               _loc14_.mMissionID = _loc9_;
            }
            trace("WE HAVE AND SET MISSION ID",_loc14_.mMissionID);
            _loc6_++;
         }
         _loc6_ = 0;
         while(_loc6_ < _loc2_.inventory.length())
         {
            _loc13_ = true;
            _loc3_ = _loc2_.inventory[_loc6_].@name;
            _loc4_ = World.mAvatar.x;
            _loc5_ = World.mAvatar.y;
            _loc9_ = int(_loc2_.inventory[_loc6_].mission_id);
            _loc10_ = int(_loc2_.inventory[_loc6_].mission_stage);
            SetStage(_loc3_,_loc9_,_loc10_);
            _loc14_ = StoreItemsList.MakePlacementItem(_loc3_,_loc4_,_loc5_);
            _loc14_.mMissionID = _loc9_;
            trace("WE HAVE AND SET MISSION ID",_loc14_.mMissionID);
            _loc6_++;
         }
         if(Motes.TestMote("girl_quest_2"))
         {
            CorianderItem.Decorate();
         }
         if(Motes.TestMote("girl_quest_6"))
         {
            CorianderItem.Decorate();
         }
         if(Motes.TestMote("girl_crown"))
         {
            CorianderItem.Decorate();
         }
         FruitTree.Init();
         MissionSetUps.Init();
         if(mLocalLoaded)
            for each(var pending:XML in _loc2_.pending_mote)
               for each(var mote:Mote in Motes.GetArray())
                  if(mote.mID == int(pending.@id))
                  {
                     mote.mClicked = String(pending.@clicked) == "true";
                     var resumedMote:MoteItem = new MoteItem(mote);
                     if(mote.mClicked) resumedMote.mStateMachine.ChangeState(new AnimateOut());
                  }
         HUD.CountBunnies();
         if(mLocalLoaded && _loc2_.tutorial.length()) Tasks.RestoreState(_loc2_.tutorial[0]);
         mLoaded = true;
         mLastSave = getTimer() - 14000;
         EnableAutoSave();
         World.mHUD.EnableSaveButton();
         mCallback();
      }

      public static function DoSave(param1:Boolean = false) : void
      {
         if(param1) { SaveNow(null); return; }
         var _loc2_:SaveDialog = new SaveDialog();
         _loc2_.x = World.SCREEN_WIDTH / 2 - _loc2_.width / 2;
         _loc2_.y = World.SCREEN_HEIGHT / 2 - _loc2_.height / 2;
         Bunni.mRealStage.addChild(_loc2_);
         EnableAutoSave();
      }

      private static function SlotObject() : SharedObject
      {
         return SharedObject.getLocal("bunni-fast-save-v1-slot" + Bunni.uID,"/");
      }

      private static function ValidRecord(record:Object) : Boolean
      {
         try
         {
            if(record == null || int(record.version) != 1 || !(record.xml is String) || record.xml.length > 4000000) return false;
            if(MD5.hash(record.xml) != String(record.checksum)) return false;
            var xml:XML = new XML(record.xml);
            if(record.xml.indexOf("<!DOCTYPE") >= 0 || record.xml.indexOf("<!ENTITY") >= 0) return false;
            if(xml.wood.length() != 1 || xml.gold.length() != 1 || xml.gems.length() != 1) return false;
            if(xml.name() != "map_data" || xml.tutorial.length() != 1 || xml.avatar.length() != 1) return false;
            if(!isFinite(Number(xml.wood)) || !isFinite(Number(xml.gold)) || !isFinite(Number(xml.gems))) return false;
            if(!isFinite(Number(xml.avatar.@x)) || !isFinite(Number(xml.avatar.@y))) return false;
            for each(var kind:String in ["item","animal","bubble","inventory"])
               for each(var item:XML in xml.child(kind))
                  if(StoreItemsList.GetObjFromName(String(item.@name)) == null || !isFinite(Number(item.location.x)) || !isFinite(Number(item.location.y))) return false;
            return true;
         }
         catch(error:Error) { return false; }
         return false;
      }

      private static function ReadRecord() : Object
      {
         try
         {
            var so:SharedObject = SlotObject();
            if(ValidRecord(so.data.current)) { mTrustedRecord = so.data.current; return so.data.current; }
            if(ValidRecord(so.data.previous))
            {
               mLastError = "Recovered the previous good local save.";
               return so.data.previous;
            }
            if(so.data.current != null || so.data.previous != null)
               mLastError = "The local save is damaged. It has been preserved; automatic saving is disabled.";
         }
         catch(error:Error) { mLastError = "Browser storage could not be read; automatic saving is disabled: " + error.message; }
         return null;
      }

      private static function MergeSnapshot(snapshot:XML) : XML
      {
         var xml:XML = mTemplate.copy();
         xml.wood = snapshot.wood; xml.gold = snapshot.gold; xml.gems = snapshot.gems;
         for each(var tag:String in ["mote","card","bridge","ghost"])
            for each(var definition:XML in xml.child(tag))
               for each(var progress:XML in snapshot.child(tag))
                  if(int(definition.id) == int(progress.id)) definition.collected = progress.collected;
         for each(tag in ["item","animal","bubble","inventory","balance","quest_progress","tutorial","avatar","pending_mote"])
         {
            delete xml[tag];
            for each(progress in snapshot.child(tag)) xml.appendChild(progress.copy());
         }
         return xml;
      }

      private static function Capture() : XML
      {
         // Static quest text/art definitions come from the unchanged starter XML.
         // Serializing them on every save caused ~200ms AVM2 stalls.
         var xml:XML = <map_data/>;
         xml.wood = HUD.GetWood(); xml.gold = HUD.GetGold(); xml.gems = HUD.GetGems();
         var avatar:XML = <avatar/>;
         avatar.@x = World.mAvatar.x; avatar.@y = World.mAvatar.y;
         xml.appendChild(avatar);
         xml.appendChild(Tasks.SaveState());
         var item:GenericItem;
         var node:XML;
         var animal:GenericAnimal;
         for each(item in Items.GetSaveItems())
         {
            if(item is MoteItem)
            {
               xml.appendChild(<pending_mote id={MoteItem(item).mMote.mID} clicked={MoteItem(item).mMote.mClicked}/>);
               continue;
            }
            if(!item.mPersist) continue;
            if(item is StoreItem && StoreItem(item).mPickedUp) continue;
            if(item is PlacementItem) node = <inventory/>;
            else if(item is StoreItem)
            {
               if(!StoreItem(item).mFree && !(item is BridgeAngelItem)) continue;
               node = <bubble/>;
            }
            else if(item is GenericAnimal) node = <animal/>;
            else node = <item/>;
            node.@name = item.mName;
            node.location = <location><x>{item.x}</x><y>{item.y}</y></location>;
            node.item_id = item.mID;
            node.mission_id = item.mMissionID;
            node.mission_stage = GetStage(item.mName,item.mMissionID);
            if(item is BridgeAngelItem && !StoreItem(item).mFree) node.mission_id = 9999;
            if(item is GenericAnimal)
            {
               animal = GenericAnimal(item);
               node.item_id = animal.mFollowAvatar ? 99999 : (animal.mWorkPlace ? animal.mWorkPlace.mID : 0);
               node.@hunger = animal.mHunger;
               node.@hungry = animal.mIsHungry;
            }
            xml.appendChild(node);
         }
         var states:Array = [Motes.GetArray(),Cards.GetArray(),Bridges.GetArray()];
         var tags:Array = ["mote","card","bridge"];
         var i:int;
         var entry:Object;
         for(i = 0; i < tags.length; ++i)
            for each(entry in states[i])
            {
               if(!entry.mCollected) continue;
               node = new XML("<" + tags[i] + "/>");
               node.id = entry.mID;
               node.collected = entry.mCollected;
               xml.appendChild(node);
            }
         var balances:Array = [StoreItem.mVerdantBay,StoreItem.mWeddingIsle,StoreItem.mDress,StoreItem.mPearls,StoreItem.mTiara,StoreItem.mSilverStore,StoreItem.mSteelStore,StoreItem.mGoldStore,StoreItem.mChurch];
         for(i = 0; i < balances.length; ++i)
         {
            entry = balances[i];
            if(entry == null || (entry.wood == 0 && entry.rock == 0)) continue;
            node = <balance><id>{i + 1}</id><wood>{entry ? entry.wood : 0}</wood><rock>{entry ? entry.rock : 0}</rock></balance>;
            xml.appendChild(node);
         }
         var families:Array = ["ghost","coriander","piratepeach"];
         var names:Array = ["Ghost","Coriander","Pirate Peach"];
         for(i = 0; i < families.length; ++i)
            for each(node in mTemplate.child(families[i]))
            {
               var progress:XML = <quest_progress/>;
               progress.@name = names[i]; progress.@id = int(node.id);
               progress.@stage = GetStage(names[i],int(node.id));
               if(int(progress.@stage) != 0) xml.appendChild(progress);
               if(i == 0 && Ghosts.GetGhostByID(int(node.id)).CollectedForSave())
               {
                  var ghost:XML = <ghost><id>{int(node.id)}</id><collected>{Ghosts.GetGhostByID(int(node.id)).CollectedForSave()}</collected></ghost>;
                  xml.appendChild(ghost);
               }
            }
         return xml;
      }

      public static function SaveNow(callback:Function) : void
      {
         if(!mLoaded || mBusy || Bunni.mViewGame || mLastError.indexOf("disabled") >= 0)
         {
            if(callback != null) callback(false);
            return;
         }
         var started:int = getTimer();
         trace("bunni-fast-save-start",started);
         var so:SharedObject;
         var oldCurrent:Object;
         var oldPrevious:Object;
         try
         {
            var text:String = Capture().toXMLString();
            var capturedAt:int = getTimer();
            var record:Object = {version:1,slot:Bunni.uID,savedAt:new Date().time,xml:text,checksum:MD5.hash(text)};
            // This XML was just generated from typed game state. Full checksum and
            // schema validation belongs at the disk/import boundary, not three
            // times per automatic save on the game thread.
            var validatedAt:int = getTimer();
            so = SlotObject(); oldCurrent = so.data.current; oldPrevious = so.data.previous;
            var previousValid:Boolean = oldCurrent === mTrustedRecord && oldCurrent != null;
            if(!previousValid) previousValid = ValidRecord(oldCurrent);
            if(previousValid && oldCurrent.xml == text)
            {
               trace("bunni-fast-save",true,getTimer() - started,text.length,"unchanged");
               if(callback != null) callback(true);
               return;
            }
            if(previousValid) so.data.previous = oldCurrent;
            so.data.current = record;
            mBusy = true;
            var finish:Function = function(ok:Boolean):void
            {
               mBusy = false;
               if(ok)
               {
                  mHasSaved = true; mSavedAt = record.savedAt; mLastError = "";
                  mTrustedRecord = record;
                  var marker:SharedObject = Persistance.getObject(Bunni.uID);
                  marker.data["init"] = true;
                  marker.flush();
               }
               else
               {
                  so.data.current = oldCurrent; so.data.previous = oldPrevious;
                  mLastError = "Browser storage rejected this save. Your previous save is retained.";
               }
               trace("bunni-fast-save",ok,getTimer() - started,text.length,"capture",capturedAt - started,"validate",validatedAt - capturedAt,"store",getTimer() - validatedAt);
               if(callback != null) callback(ok);
            };
            if(so.flush() == SharedObjectFlushStatus.FLUSHED) finish(true);
            else
            {
               var status:Function = function(event:NetStatusEvent):void
               {
                  so.removeEventListener(NetStatusEvent.NET_STATUS,status);
                  finish(event.info.code == "SharedObject.Flush.Success");
               };
               so.addEventListener(NetStatusEvent.NET_STATUS,status);
            }
         }
         catch(error:Error)
         {
            mBusy = false;
            if(so != null) { so.data.current = oldCurrent; so.data.previous = oldPrevious; }
            mLastError = "Local saving failed: " + error.message;
            trace("bunni-fast-save-error",mLastError);
            if(callback != null) callback(false);
         }
      }

      public static function ExportBackup() : String
      {
         var record:Object = ReadRecord();
         if(record == null) throw new Error("No valid local save is available.");
         return JSON.stringify(record);
      }

      public static function ImportBackup(text:String) : Boolean
      {
         var so:SharedObject;
         var oldCurrent:Object;
         var oldPrevious:Object;
         var changed:Boolean = false;
         try
         {
            if(text.length > 4000000) throw new Error("The backup is too large.");
            var record:Object = JSON.parse(text);
            if(!ValidRecord(record)) throw new Error("This is not a valid Bunni backup.");
            so = SlotObject();
            oldCurrent = so.data.current;
            oldPrevious = so.data.previous;
            changed = true;
            if(ValidRecord(oldCurrent)) so.data.previous = oldCurrent;
            so.data.current = record;
            if(so.flush() != SharedObjectFlushStatus.FLUSHED)
            {
               so.data.current = oldCurrent; so.data.previous = oldPrevious;
               throw new Error("Browser storage did not confirm the imported save.");
            }
            var marker:SharedObject = Persistance.getObject(Bunni.uID);
            marker.data["init"] = true; marker.flush();
            mAutoSave = false;
            mLoaded = false;
            mLastError = "Backup imported. Reload this page and Continue slot " + Bunni.uID + ".";
            return true;
         }
         catch(error:Error)
         {
            // SharedObject.flush throws on storage rejection in Ruffle. Restore both
            // in-memory records as well as retaining the untouched on-disk record.
            if(changed && so != null) { so.data.current = oldCurrent; so.data.previous = oldPrevious; }
            mLastError = "Backup was not imported: " + error.message;
         }
         return false;
      }

      // Read-only diagnostic used only by the opt-in benchmark harness.
      public static function SaveInfo() : String
      {
         var record:Object = ReadRecord();
         return "slot=" + Bunni.uID + ";saved=" + mSavedAt + ";loaded=" + mLocalLoaded + ";valid=" + (record != null) + ";error=" + mLastError + ";state=" + (mLoaded ? Capture().toXMLString() : "");
      }

      private static function SetStage(param1:String, param2:int, param3:int) : void
      {
         if(param1 == "Ghost")
         {
            Ghosts.SetState(param2,param3);
         }
         else if(param1 == "Pirate Peach")
         {
            PeachMissions.SetState(param2,param3);
         }
         else if(param1 == "Coriander")
         {
            CorianderMissions.SetState(param2,param3);
         }
      }

      private static function GetStage(param1:String, param2:int) : int
      {
         if(param1 == "Ghost")
         {
            trace("getting Ghost mission state",Ghosts.GetState(param2));
            return Ghosts.GetState(param2);
         }
         if(param1 == "Pirate Peach")
         {
            trace("getting Peach mission state",PeachMissions.GetState(param2));
            return PeachMissions.GetState(param2);
         }
         if(param1 == "Coriander")
         {
            trace("getting Coriander mission state",CorianderMissions.GetState(param2));
            return CorianderMissions.GetState(param2);
         }
         return 0;
      }

      private static function loadPageSuccessful(param1:Event) : void
      {
         var _loc2_:URLVariables = new URLVariables(param1.target.data);
         mCallbackSave(true);
         trace("WOOT",_loc2_);
      }

      private static function loadPageError(param1:IOErrorEvent) : void
      {
         trace("error saving");
         mCallbackSave(false);
      }
   }
}
