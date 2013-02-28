﻿package com.sqwiggle {	import com.sqwiggle.Member;	import com.sqwiggle.Self;	import com.sqwiggle.GUID;	import flash.utils.Dictionary;	public class Conversation extends Object {		public var id:String;		public var members:Object;		private var length:Number;		public function Conversation(id:String=null) {			this.members = new Object();			this.id = id;		}						public function getMembersAsList() {						var list:String = "";			var usernames:Array = new Array();			var cutoff = 3;						for (var i in members) {				if (members[i].userName == "Me") continue;								usernames.push(members[i].userName);			}						if (usernames.length < cutoff+1) {				list = usernames.join(', ');			} else {				list = usernames.slice(0, cutoff).join(', ') + " and " + (usernames.length-cutoff) + " others";			}						return list;		}						public function removeAllMembers(inConversation:Boolean = false):void {			for (var i in members) {				removeMember(members[i], inConversation);			}		}						public function addMember(member:Member, inConversation:Boolean=false):void {			Sqwiggle.trace('Conversation:addMember', member.userId);						members[member.userId] = member;			member.audioOn(inConversation);			length++;		}						public function removeMember(member:Member, inConversation:Boolean=false):void {			Sqwiggle.trace('Conversation:removeMember', member.userId);			delete members[member.userId];			member.audioOff(inConversation);			length--;		}						public function hasMember(member:Member):Boolean {			return !!members[member.userId];		}						public function isEmpty():Boolean {			return length == 1;		}	}}