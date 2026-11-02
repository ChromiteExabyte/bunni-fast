package Save
{
   import World.World;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.net.FileFilter;
   import flash.net.FileReference;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import fl.controls.TextInput;

   [Embed(source="/_assets/assets.swf", symbol="symbol157")]
   public class SaveDialog extends MovieClip
   {
      public var mFeedback:TextField;
      public var mUserName:TextInput;
      public var mWaiting:MovieClip;
      public var mBlurb:MovieClip;
      public var mPassword:TextInput;
      public var mError:MovieClip;
      public var mShare:TextField;
      public var mSaved:MovieClip;
      public var mDone:MovieClip;
      public var mSave:MovieClip;
      public var mCancel:MovieClip;
      private var mBackupFile:FileReference;
      private var mTitle:TextField;
      private var mStatus:TextField;

      public function SaveDialog()
      {
         super();
         World.PauseGame();
         for(var i:int = 0; i < numChildren; ++i) getChildAt(i).visible = false;
         graphics.lineStyle(1,0x999999);
         graphics.beginFill(0xF5F5F0);
         graphics.drawRoundRect(0,0,440,270,22,22);
         graphics.endFill();
         mTitle = label("Saving your island...",22,24,396,32,20);
         mStatus = label("",22,78,396,100,14);
         mDone = button("Done",316,218,102,close);
         button("Export backup",22,218,132,exportBackup);
         button("Import backup",166,218,138,importBackup);
         Save.SaveNow(function(ok:Boolean):void
         {
            mTitle.text = ok ? "Your island is saved" : "Saving needs attention";
            mStatus.text = ok ? "Saved in this browser, slot " + Bunni.uID + ".\nChoose Continue next time.\n\nExport a backup to keep a copy outside the browser. Clearing site data removes browser saves." : Save.mLastError;
         });
      }

      private function label(text:String,x:Number,y:Number,w:Number,h:Number,size:int) : TextField
      {
         var field:TextField = new TextField();
         field.defaultTextFormat = new TextFormat("Rockwell",size,0x333333);
         field.x = x; field.y = y; field.width = w; field.height = h;
         field.multiline = true; field.wordWrap = true; field.selectable = false;
         field.mouseEnabled = false;
         field.text = text; addChild(field); return field;
      }

      private function button(text:String,x:Number,y:Number,w:Number,handler:Function) : MovieClip
      {
         var clip:MovieClip = new MovieClip();
         clip.graphics.lineStyle(1,0xAAAAAA);
         clip.graphics.beginFill(0xFFFFFF);
         clip.graphics.drawRoundRect(0,0,w,30,8,8); clip.graphics.endFill();
         clip.x = x; clip.y = y; clip.buttonMode = true;
         clip.mouseChildren = false;
         var field:TextField = label(text,0,0,w,27,13);
         removeChild(field); clip.addChild(field);
         field.y = 6; field.defaultTextFormat = new TextFormat("Rockwell",13,0x333333,null,null,null,null,null,"center"); field.text = text;
         clip.addEventListener(MouseEvent.CLICK,handler);
         addChild(clip); return clip;
      }

      private function exportBackup(event:MouseEvent) : void
      {
         try
         {
            mBackupFile = new FileReference();
            mBackupFile.addEventListener(IOErrorEvent.IO_ERROR,fileError);
            mBackupFile.save(Save.ExportBackup(),"bunni-slot-" + Bunni.uID + ".json");
         }
         catch(error:Error) { mStatus.text = error.message; }
      }

      private function importBackup(event:MouseEvent) : void
      {
         mBackupFile = new FileReference();
         mBackupFile.addEventListener(IOErrorEvent.IO_ERROR,fileError);
         mBackupFile.addEventListener(Event.SELECT,function(selected:Event):void
         {
            mBackupFile.addEventListener(Event.COMPLETE,function(loaded:Event):void
            {
               var ok:Boolean = Save.ImportBackup(mBackupFile.data.readUTFBytes(mBackupFile.data.length));
               mStatus.text = Save.mLastError;
               mTitle.text = ok ? "Backup imported" : "Backup was not imported";
               if(ok) mDone.visible = false;
            });
            mBackupFile.load();
         });
         try { mBackupFile.browse([new FileFilter("Bunni backup (*.json)","*.json")]); }
         catch(error:Error) { mStatus.text = error.message; }
      }

      private function fileError(event:IOErrorEvent) : void { mStatus.text = "The backup file could not be read or written."; }
      private function close(event:MouseEvent) : void
      {
         World.Continue();
         if(parent) parent.removeChild(this);
      }
   }
}
