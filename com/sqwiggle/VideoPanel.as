﻿package com.sqwiggle {	import flash.utils.Dictionary;	import flash.net.NetStream;	import flash.net.NetConnection;	import flash.events.NetStatusEvent;	import flash.external.ExternalInterface;	import flash.display.Sprite;	import com.sqwiggle.Member;	import com.sqwiggle.Self;	import com.sqwiggle.GUID;	public class VideoPanel extends Sprite {		public var connection:NetConnection;		public var self:Self;		private var members:Dictionary;		private var length:Number;		public function VideoPanel(self:Self) {			this.self = self;			this.members = new Dictionary();						// setup a new video connection for this panel and get connecting			connection = new NetConnection();			connection.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);			connection.connect('rtmfp://p2p.rtmfp.net', '56ec6665a4c675c72fb85db7-b6153286fa1e');		}						public function addMember(member:Member):void {						// dont connect ourselves here, this is done elsewhere			if (member.peerId == connection.nearID) {				trace('NOTICE: attempted to connect self');				return;			}						if (members[member.userId]) {				trace('NOTICE: peer already present');				return;			}						trace('VideoPanel:addMember', member.peerId);			members[member.userId] = member;			// connect video			member.connectToVideo(connection);						// add to stage			addChild(member);			length++;						relayout();		}						public function removeMember(memberId:String):void {			trace('VideoPanel:removeMember');			var member = members[memberId];						// handle if we're asked to remove a member that			// has already been removed or not yet connected			if (!member) return;						// disconnect video			member.disconnectFromVideo();					// remove from stage			removeChild(member);			length--;						delete members[memberId];						relayout();		}						public function getMembers():Dictionary {			return members;		}						public function getMembersCount():Number {			return length;		}						public function inConversation(member:Member):Boolean {						// convert to boolean			return !!members[member.userId];		}						public function relayout():void {			trace('VideoPanel:relayout');									// relayout video feeds in grid for now, this is currently			// assuming that self is always in the top right corner.			var key = 1;						for (var i in members) {				members[i].x = members[i].width  * (key % 3);				members[i].y = members[i].height * (Math.ceil((key+1) / 3)-1);								trace('positioning: ' + i + ' at ' + members[i].x + '|' + members[i].y);				key++;			}						var centerX = stage.stageWidth / 2;			var centerY = stage.stageHeight / 2;			trace('center', centerX, centerY);						var halfPanelWidth = this.width / 2;			var halfPanelHeight = this.height / 2;			trace('halfpanel', halfPanelWidth, halfPanelHeight);						this.x = centerX-halfPanelWidth;			this.y = centerY-halfPanelHeight;			trace('post', this.x, this.y);						// change layout depending on how many clients are connected			// lower numbers have custom layouts to make the most of the space			/*			switch(members.length) {				case 1:				case 2:				case 3:				case 4:				default:			}			*/		}						private function onNetStatus(e:NetStatusEvent):void {			switch (e.info.code) {				case 'NetConnection.Connect.Success':										// set up our video stream					self.connectToVideo(connection);										// add video to stage					addChild(self);										relayout();										// dispatch event to update peerId					ExternalInterface.call('update_peer_id', self.userId, connection.nearID);				break;			}		}	}}