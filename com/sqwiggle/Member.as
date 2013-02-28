﻿package com.sqwiggle {	import flash.display.Sprite;	import flash.display.Shape;	import flash.display.MovieClip;	import flash.media.Video;	import flash.net.NetConnection;	import flash.net.NetStream;	import flash.net.NetStreamInfo;	import flash.events.Event;	import flash.events.MouseEvent;	import flash.events.NetStatusEvent;	import flash.events.TimerEvent;	import flash.text.TextField;	import flash.text.TextFormat;	import fl.transitions.Tween;	import fl.transitions.easing.*;	import flash.utils.Timer;	public class Member extends Sprite {				public static const MAX_WIDTH = 400;		public static const MAX_HEIGHT = 300;		public static const INFOBAR_HEIGHT = 35;		public var connection	:NetConnection;		public var userId		:String;		public var peerId		:String;		public var userName		:String;				protected var stream	:NetStream;		protected var video 	:Video;		protected var infoBar	:Sprite;		protected var activity	:MovieClip;		protected var timeField :TextField;		protected var nameField :TextField;		public function Member(userId:String, peerId:String, userName:String='Anonymous') {			this.userId = userId;			this.peerId = peerId;			this.userName = userName;			render(300, 225);						addEventListener(MouseEvent.MOUSE_OVER, hoverOver);			addEventListener(MouseEvent.MOUSE_OUT, hoverOut);			addEventListener(Event.ENTER_FRAME, updateActivity);						var timer = new Timer(1000);            timer.addEventListener(TimerEvent.TIMER, updateTime);            timer.start();		}				public function render(w:Number, h:Number):void {						w = Math.min(Member.MAX_WIDTH, w);			h = Math.min(Member.MAX_HEIGHT, h);						if (!video) {				video = new Video();				addChild(video);			}						video.width  = w;			video.height = h;						if (!activity) {				activity = new ActivityIndicator();				activity.visible = false;				addChild(activity);			}						activity.x = 0;			activity.y = h;						drawInfoBar();		}				public function hideVideo():void {			Sqwiggle.trace('Pausing video for', userId);			stream.receiveVideo(false);		}				public function showVideo():void {			stream.receiveVideo(true);		}				private function drawInfoBar():void {						if (infoBar) removeChild(infoBar);			infoBar = new Sprite();			infoBar.y = video.height-Member.INFOBAR_HEIGHT;			infoBar.alpha = 0;			addChild(infoBar);			var opaqueBar = new Sprite();			opaqueBar.graphics.beginFill(0x000000, 0.3);			opaqueBar.graphics.drawRect(0,0,video.width,Member.INFOBAR_HEIGHT);			opaqueBar.graphics.endFill();			infoBar.addChild(opaqueBar);						var textFormat:TextFormat = new TextFormat();			textFormat.font = "Arial";			textFormat.size = 16;						nameField = new TextField();			nameField.x = 10;			nameField.y = 6; // padding			nameField.defaultTextFormat = textFormat;			nameField.width = video.width-50;			nameField.height = infoBar.height;			nameField.selectable = false;			nameField.textColor = 0xFFFFFF;			nameField.text = userName;			nameField.alpha = 0.8;			infoBar.addChild(nameField);						timeField = new TextField();			timeField.x = video.width-50;			timeField.y = 6; // padding			timeField.defaultTextFormat = textFormat;			timeField.width = 50;			timeField.height = infoBar.height;			timeField.selectable = false;			timeField.textColor = 0xFFFFFF;			timeField.text = Utils.getFormattedTime();			timeField.alpha = 0.8;						infoBar.addChild(timeField);		}						public function connectToVideo(connection:NetConnection):void {			Sqwiggle.trace('Connecting to video of: ' + userId + ', stream: ' + peerId);						stream = new NetStream(connection, peerId);			stream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);			stream.receiveAudio(false);			stream.play(userId);			video.attachNetStream(stream);		}				public function disconnectFromVideo():void {			removeChild(video);			stream.close();		}				protected function updateActivity(event:Event):void {			/*			var bytes:Number = stream.info.audioBytesPerSecond;						if (bytes) {				var maxActivityLevel = 5500;				var activityLevel = (Math.max(0, bytes-1000)/100) / (maxActivityLevel/100)				activity.alpha = 0.5 + (activityLevel/2);			}			*/		}				protected function updateTime(event:Event):void {						timeField.text = Utils.getFormattedTime();		}				public function audioOn(conversationInProgress:Boolean=false):void {			stream.receiveAudio(true);			activity.visible = true;			nameField.x = 40;						if (conversationInProgress) {				new Tween(video, "alpha", Regular.easeIn, 1, alpha, 0.5, true);			}		}				public function audioOff(conversationInProgress:Boolean=false):void {			stream.receiveAudio(false);			activity.visible = false;			nameField.x = 10;			if (conversationInProgress) {				new Tween(video, "alpha", Regular.easeIn, 1, alpha, 1, true);			}		}				public function onNetStatus(event:NetStatusEvent):void {			Sqwiggle.trace('Net status ' + peerId + ': ' + event.info.code);		}				private function hoverOver(event:MouseEvent):void {			new Tween(infoBar, "alpha", Regular.easeIn, 0, 1, 0.3, true);		}				private function hoverOut(event:MouseEvent):void {			new Tween(infoBar, "alpha", Regular.easeIn, 1, 0, 0.3, true);		}	}}