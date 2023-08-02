define(["jraf/models/Content","jraf/models/TabManager","jraf/models/PopupManager","jraf/models/RegionManager","jraf/models/ModalPageManager"],(function(n,e,o,t,a){"use strict";function r(n){if(!("object"==typeof n&&null!==n&&(n.tabManager instanceof e||n.regionManager instanceof t)&&n.popupManager instanceof o&&n.globalModalPageManager instanceof a))throw new TypeError("ContentManager: Invalid configuration.");this.tabManager=n.tabManager,this.popupManager=n.popupManager,this.regionManager=n.regionManager,this.globalModalPageManager=n.globalModalPageManager}return r.prototype.openContent=function(e){if(!(e instanceof n)){throw new Error("ContentManager.openContent must be called with Content")}if(e.isNewWindowContent()){var o=e.getUrl();window.open(o,"_blank")}else e.isPopupContent()?this.popupManager.openContent(e):e.isGlobalModalPageContent()?this.globalModalPageManager.openContent(e):this.tabManager?this.tabManager.openContent(e):this.regionManager.openContent(e)},r.prototype.openModalPageInContent=function(n,e){(this.tabManager?this.tabManager:this.regionManager).openModalPageInContent(n,e)},r.prototype.closeContent=function(e){if(void 0!==e){if(!(e instanceof n))throw new Error("ContentManager.closeContent must be called with Content.");if(e.isNewWindowContent())throw new Error("ContentManager.closeContent is not supported for new window content.");e.isPopupContent()?this.closePopup():e.isGlobalModalPageContent()?this.closeGlobalModalPage():this.tabManager?this.tabManager.closeContent(e):this.regionManager.closeContent(e)}else this.tabManager.closeContent()},r.prototype.closePopup=function(){return this.popupManager.closeContent()},r.prototype.closeGlobalModalPage=function(){return this.globalModalPageManager.closeContent()},r}));