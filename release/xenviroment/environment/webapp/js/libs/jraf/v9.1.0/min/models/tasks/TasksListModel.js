define(["ojs/ojcore","knockout","jraf/jrafcore","jraf/models/UIShellManager","jraf/models/Content","jraf/models/favorites/FavoritesContent","jraf/utils/ValidationUtils","ojs/ojarraytreedataprovider"],(function(t,e,i,o,n,r,s,l){"use strict";var a=t.Translations.getTranslatedString;function h(t){if(!s.isObjectStrict(t)||!s.isFunction(t.getTasks))throw new TypeError("TasksListModel: Missing required getTasks callback");this.homeNodeId=i.UIShell.generateUniqueId(),this.Tl=e.observableArray([]),this.Ll=e.observable({id:this.homeNodeId,label:a("jraf.sidebar.home"),isHome:!0}),this.Sl=t.getTasks,this.Fl=t.taskId,this.Gl=this.Fl?o.getDataPromise(this.Fl):this.Sl(),this.Ul=null,this._l=null,this.xl=!!t.favoritesEnabled,this.xl&&(this.Il=t.favoritesType,this.Al=r.getInstance()),this.Vl=null,this.zl={},this.Dl=e.observable(null),this.Jl=e.observable(!1),this.Kl()}return h.prototype.Kl=function(){var t=this;return o.startProcessingIndicator(),t.Gl.then((function(e){t.Nl(e)})).catch((function(e){t.Ol(e)}))},h.prototype.Nl=function(e){if(t.Logger.info("TasksListModel._handleSuccessfulGetTasks: Entering."),"object"==typeof e&&null!==e){this.Ul=e;try{this._l=new n(e)}catch(e){t.Logger.warn("TasksListModel._handleSuccessfulGetTasks: invalid data returned."),this.Ul=null,this._l=null}this._l instanceof n&&(this.Vl=this.$e(this._l,{}),this.Ql(this._l))}this.Jl(!0),o.stopProcessingIndicator()},h.prototype.$e=function(t,e){if((e[t.getId()]=t).isFolder())for(var i=t.getChildren(),o=0;o<i.length;o++){var n=i[o];this.$e(n,e)}return e},h.prototype.Ql=function(t){for(var e=[],i=t.getChildren(),o=0;o<i.length;o++){var n=i[o],r=this.Rl(n);e.push(r)}this.Dl(new l(e,{keyAttributes:"attr.id"}))},h.prototype.Rl=function(t){var e=this,o=i.UIShell.generateUniqueId();this.zl[o]=t.getId();var n={attr:{id:o,label:t.getTitle(),isSection:t.isSection(),isFavorite:this.xl&&this.Al.trackFavoriteState(t.getId()),toggleFavoriteSelection:function(t,i){e.Wl(i.data.attr)}}};if(t.isFolder()){for(var r=[],s=t.getChildren(),l=0;l<s.length;l++){var a=s[l],h=this.Rl(a);r.push(h)}n.children=r,n.attr.isFolder=!0}return n},h.prototype.Ol=function(e){t.Logger.warn("TasksListModel._handleFailedGetTasks: failed loading data with reason "+e),o.stopProcessingIndicator()},h.prototype.getUIContent=function(t){var e=this.zl[t];if(!e)throw new Error("TasksListModel.getContent: no record for UI id: "+t);return this.getContent(e)},h.prototype.getContent=function(t){var e=this.Vl[t];if(!(e instanceof n))throw new Error("TasksListModel.getContent: no content record for content id: "+t);return e},h.prototype.handleMenuBeforeExpand=function(e){var i=this.getUIContent(e);return t.Logger.info("TasksListModel.handleMenuBeforeExpand: Expanding %s (%s).",e,i.getId()),this.Xl({id:e,label:i.getTitle(),isHome:!1}),!0},h.prototype.handleMenuBeforeCollapse=function(e){var i=this.getUIContent(e);return t.Logger.info("TasksListModel.handleMenuBeforeCollapse: Collapsing %s (%s).",e,i.getId()),this.Yl(),!0},h.prototype.Xl=function(t){this.Ll().id!==t.id&&(this.Tl.push(this.Ll()),this.Ll(t))},h.prototype.Yl=function(){var t=this.Tl.pop();this.Ll(t)},h.prototype.getHierarchyDrillPath=function(){return this.Tl},h.prototype.getDrilledNode=function(){return e.pureComputed((function(){return this.Ll()}),this)},h.prototype.getRootContent=function(){return this._l},h.prototype.getMenuData=function(){return this.Dl},h.prototype.getMenuDataLoaded=function(){return e.pureComputed((function(){return this.Jl()}),this)},h.prototype.isFavoritesEnabled=function(){return this.xl},h.prototype.Wl=function(t){t.isFavorite()?this.Al.removeFavorite(this.zl[t.id]):this.Al.addFavorite(this.zl[t.id],t.label,this.Il)},h}));