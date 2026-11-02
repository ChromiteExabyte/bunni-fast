package Quests
{
   import FSM.BaseStateMachine;
   import MapItems.Ghosts.QuestItem;

   public class Quest
   {

      public static const kNotStarted:int = 0;

      public static const kIntroRead:int = 1;

      public static const kTaskCompete:int = 2;

      public static const kGiftRecived:int = 3;

      public var mID:int;

      protected var mName:String;

      public var mIntro:Array;

      public var mDuring:Array;

      public var mComplete:Array;

      public var mSetUp:String;

      protected var mTriggerMote:String;

      protected var mCompleteMote:String;

      public var mRewardItem:String;

      public var mWood:int;

      public var mGold:int;

      public var mGems:int;

      protected var mCollected:Boolean;

      public var mDone:Boolean;

      public var mCurrentText:Array;

      protected var mStateMachine:BaseStateMachine;

      public var mMissionItem:QuestItem;

      public var mMissionStage:int = 0;

      public function Quest(param1:int, param2:String, param3:Array, param4:Array, param5:Array, param6:String, param7:String, param8:String, param9:String, param10:int, param11:int, param12:int, param13:Boolean)
      {
         super();
         this.mID = param1;
         this.mName = param2;
         this.mIntro = param3;
         this.mDuring = param4;
         this.mComplete = param5;
         this.mSetUp = param6;
         this.mTriggerMote = param7;
         this.mCompleteMote = param8;
         this.mRewardItem = param9;
         this.mWood = param10;
         this.mGold = param11;
         this.mGems = param12;
         this.mCollected = param13;
         this.mDone = param13;
      }

      public function CollectedForSave() : Boolean { return this.mCollected; }

      public function TestComplete() : void
      {
      }

      public function Init() : void
      {
      }

      public function AdvanceState() : void
      {
      }
   }
}
