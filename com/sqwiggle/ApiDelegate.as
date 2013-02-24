﻿package com.sqwiggle {    import flash.events.*;    import flash.net.*;	import com.sqwiggle.events.ApiEvent;	    public class ApiDelegate extends EventDispatcher {  		public var loader:URLLoader;         public function ApiDelegate(method:String, path:String, options:Object = null) {            loader = new URLLoader();            configureListeners();             var request:URLRequest = new URLRequest(path);			var variables:URLVariables = new URLVariables();  						for(var key:String in options){				variables[key] = String(options[key]);			}			request.data = variables;						if (method == "GET") {				request.method = "GET";						// unfortunately flash does not support HTTP methods for PUT and DELETE			} else {				request.method = "POST";				request.requestHeaders = [new URLRequestHeader("X-HTTP-Method-Override", method)];			}            			try {                loader.load(request);            } catch (error:Error) {                trace("Unable to load requested document.");            }        }         private function configureListeners():void {            loader.addEventListener(Event.COMPLETE, completeHandler);            loader.addEventListener(Event.OPEN, openHandler);            loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);            loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);            loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);        }         private function completeHandler(event:Event):void {			dispatchEvent(new ApiEvent(Event.COMPLETE, JSON.parse(loader.data)));        }         private function openHandler(event:Event):void {            trace("openHandler: " + event);        }         private function progressHandler(event:ProgressEvent):void {            trace("progressHandler loaded:" + event.bytesLoaded + " total: " + event.bytesTotal);        }         private function securityErrorHandler(event:SecurityErrorEvent):void {            trace("securityErrorHandler: " + event);        }         private function httpStatusHandler(event:HTTPStatusEvent):void {            trace("httpStatusHandler: " + event);        }         private function ioErrorHandler(event:IOErrorEvent):void {            trace("ioErrorHandler: " + event);			trace(event.target.data);        }    }}