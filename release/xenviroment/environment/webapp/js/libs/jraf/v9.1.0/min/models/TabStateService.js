define(["jraf/models/TabState","ojs/ojcore","jraf/jrafcore","ojs/ojrouter"],(function(e,t,o){"use strict";var r="jraf.TabStateService.routerState",a="jraf.TabStateService.tabState",n={Rf:function(){if(o.App.getRootRouter()){var e=o.App.getRootRouterState();return e?e.path:null}return t.Router.rootInstance.stateId()},save:function(t){window.sessionStorage.setItem(r,n.Rf()),window.sessionStorage.setItem(a,e.serialize(t))},get:function(){return n.Rf()!==window.sessionStorage.getItem(r)&&n.clear(),e.deserialize(window.sessionStorage.getItem(a))},clear:function(){window.sessionStorage.removeItem(r),window.sessionStorage.removeItem(a)}};return n}));