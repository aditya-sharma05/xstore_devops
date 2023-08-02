/**
 * @license
 * Copyright (c) 2014, 2020, Oracle and/or its affiliates.
 * Licensed under The Universal Permissive License (UPL), Version 1.0
 * as shown at https://oss.oracle.com/licenses/upl/
 * @ignore
 */
define(["ojs/ojcore","knockout","ojs/ojcontext","ojs/ojcomposite","ojs/ojmodule"],function(e,o,n,i){"use strict";i.register("oj-module",{view:'\x3c!-- ko ojModule: {"view":config().view, "viewModel":config().viewModel,"cleanupMode":config().cleanupMode,"animation":animation} --\x3e\x3c!-- /ko --\x3e',metadata:{properties:{animation:{type:"object"},config:{type:"object|Promise",properties:{cleanupMode:{type:"string",enumValues:["none","onDisconnect"],value:"onDisconnect"},view:{type:"Array<Node>"},viewModel:{type:"object"}}}},events:{ojViewDisconnected:{},ojTransitionStart:{},ojViewConnected:{},ojTransitionEnd:{}},extension:{}},viewModel:function(e){var i=e.element,t=e.properties,c=this;function s(){c.busyCallback||(c.busyCallback=n.getContext(i).getBusyContext().addBusyState({description:"oj-module is waiting on config Promise resolution"}));var e=Promise.resolve(t.config);c.configPromise=e,e.then(function(o){e===c.configPromise&&(c.config(o),c.busyCallback(),c.busyCallback=null)},function(o){if(e===c.configPromise)throw c.busyCallback(),c.busyCallback=null,o})}function a(e,n){var i=e&&e[n];"function"==typeof i&&o.ignoreDependencies(i,e)}function l(e,o,n){var t={};o&&(t.viewModel=o),n&&(t.view=n);var c=new CustomEvent(e,{detail:t});i.dispatchEvent(c)}this.animation=e.properties.animation,this.config=o.observable({view:[]}),this.configPromise=null,this.propertyChanged=function(e){"animation"===e.property?c.animation=e.value:"config"===e.property&&s()},s(),this.connected=function(){var e,o,n=this.config();(o=(e=n)?e.view:null)&&o.length>0&&i.contains(o[0])&&(a(n.viewModel,"connected"),l("ojViewConnected",n.viewModel))}.bind(this),this.disconnected=function(){var e=this.config();a(e.viewModel,"disconnected"),l("ojViewDisconnected",e.viewModel,e.view)}.bind(this)}})});