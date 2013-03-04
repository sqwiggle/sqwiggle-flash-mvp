﻿package com.sqwiggle {	import com.sqwiggle.Conversation;	import com.sqwiggle.Self;	import com.sqwiggle.events.ApiEvent;	import com.sqwiggle.events.ConversationEvent;		import flash.events.Event;	import flash.net.URLLoader;	import flash.events.EventDispatcher;		public class Conversations extends EventDispatcher {				private var ongoing:Object;		private var colours:Array;		private var self:Self;		public var members:Object;				public function Conversations(self:Self, members:Object) {			this.ongoing = new Object();			this.members = members;			this.self = self;						// make an API request to get ongoing conversations			var request = Api.getRequest('/conversations');						request.addEventListener(Event.COMPLETE, function(event:ApiEvent) {				Sqwiggle.trace('Conversations', JSON.stringify(event.data));				updateMembers(event.data);			});		}						public function updateMembers(conversations:Array):void {						// first find if the current user is in any conversation			var selfInConversation = getSelfInConversations(conversations);			var previouslyInConversation = clearOldConversations(conversations);									// then for each conversation that is occuring, ensure the			// correct members are present in the conversation (we may			// need to remove members that have left)			for (var i in conversations) {				var key = 'convo' + i;								// we dont know about this conversation				if (!ongoing[key]) {					Sqwiggle.trace('creating new conversation');					ongoing[key] = new Conversation(conversations[i].id, conversations[i].color_id);				}								var conversation = ongoing[key];				var existingMembers = conversation.members;				var selfInCurrentConversation = selfInConversation && (selfInConversation.id == conversation.id);				var member;				if (selfInCurrentConversation) {					Sqwiggle.trace('Were in this conversation');				} else {					Sqwiggle.trace('Were not in this conversation');				}				// find existing members that should leave the convo				for (var j in existingMembers) {										// check if this user is still in the convo					var filter = conversations[i].users.filter(function(user){ return user.id == this.userId; }, existingMembers[j]);					var inConversation = !!filter.length;					member = existingMembers[j];										if (!inConversation) {						Sqwiggle.trace('Member has left a conversation', member.userId, conversation.id);						conversation.removeMember(member, selfInCurrentConversation);					}				}				// for every user that should be in this conversation				Sqwiggle.trace('processing users');				for (var k in conversations[i].users) {					var user = conversations[i].users[k];					Sqwiggle.trace('Looking at user', user.id);										if (user.id == self.userId) {						member = self;					} else {						member = members[user.id];					}										if (!member) {						Sqwiggle.trace('Couldnt find member for user', user.id);					} else {						conversation.addMember(member, selfInCurrentConversation);					}										if (member && !conversation.hasMember(member)) {												if (selfInCurrentConversation) {							Sqwiggle.trace('adding member to your conversation', member.userId);						} else {							Sqwiggle.trace('adding member to conversation', member.userId, conversation.id);						}						conversation.addMember(member, selfInCurrentConversation);					}				}			}						if (!previouslyInConversation && selfInConversation) {				conversation = getConversationForMember(self);								dispatchEvent(new ConversationEvent("conversationstarted", conversation.getMembersAsList()));			} else if(previouslyInConversation && !selfInConversation) {								dispatchEvent(new ConversationEvent("conversationended", null));			}						dispatchEvent(new Event("conversationsupdated"));		}						private function getSelfInConversations(conversations:Array) {						var selfInConversation = false;						// search conversations in update for users presence			for (var a in conversations) {				for (var b in conversations[a].users) {					if (conversations[a].users[b].id == self.userId) {						selfInConversation = conversations[a];						Sqwiggle.trace('We are in a conversation, lucky us');					}				}			}						return selfInConversation;		}						private function clearOldConversations(conversations:Array):Boolean {						var previouslyInConversation = false;						// search ongoing conversations for those that no longer			// exist in the update. These need to be tidied up and removed			for (var c in ongoing) {								if (ongoing[c].hasMember(self)) {					previouslyInConversation = true;				}								var noLongerExists = true;				for (var d in conversations) {					if (conversations[d].id == ongoing[c].id) {						noLongerExists = false;						break;					}				}								if (noLongerExists) {					Sqwiggle.trace('Removing conversation from our cache that no longer exists', c);					ongoing[c].removeAllMembers();					delete ongoing[c];				}			}						return previouslyInConversation;		}						public function getConversationForMember(member:Member):Conversation {						for (var i in ongoing) {				if (ongoing[i].hasMember(member)) {					return ongoing[i];				}			}						return null;		}	}}