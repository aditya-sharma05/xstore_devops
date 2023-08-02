define(["knockout","ojs/ojcore","jraf/models/Content","jraf/models/UIShellManager","jraf/utils/ValidationUtils","jraf/utils/ParseUtils","ojs/ojbutton"],(function(e,t,i,r,o,n){"use strict";var a=t.Translations.getTranslatedString;function s(t){var i=this;if(!o.isObjectStrict(t)||!o.isArray(t.topics)&&!e.isObservable(t.topics))throw new TypeError("HelpTiles: Invalid parameters");this.ie(),this.topics=e.observableArray([]),this.ee=t.topics,this.te(e.unwrap(this.ee)),e.isObservable(this.ee)&&this.ee.subscribe((function(e){i.te(e)}))}return s.MAX_TILE_DESCRIPTION_CHARS=500,s.HELP_TYPE_DOCUMENT="document",s.HELP_TYPE_VIDEO="video",s.VIDEO_ICON="jraf-help-tile-video-icon",s.DOC_ICON="jraf-help-tile-document-icon",s.DEFAULT_COLOR=(s.COLORS={lightblue:"42ADEB",red:"E95A38",lightgreen:"76C66E",purple:"9A66AF",blue:"6296CE",grey:"92A0AD",orange:"F09543",turquiose:"22B5BD",green:"67B460"}).lightblue,s.prototype.ie=function(){this.ne={},this.ne[s.HELP_TYPE_DOCUMENT]=s.DOC_ICON,this.ne[s.HELP_TYPE_VIDEO]=s.VIDEO_ICON,this.oe={},this.oe[s.HELP_TYPE_DOCUMENT]=a("jraf.appframe.documentHelpLaunchLabel"),this.oe[s.HELP_TYPE_VIDEO]=a("jraf.appframe.videoHelpLaunchLabel")},s.prototype.te=function(e){for(var i=[],r=0;r<e.length;r++){var o=e[r];void 0!==this.ne[o.type]?i.push({name:o.name,description:n.getTruncatedString(o.description,s.MAX_TILE_DESCRIPTION_CHARS),url:o.url,imageSrc:o.imageSrc,type:o.type,typeIconClass:this.ne[o.type],typeLabel:this.oe[o.type],color:"#"+(s.COLORS[o.color]||s.DEFAULT_COLOR)}):t.Logger.warn("HelpTiles._parseData: Invalid type for entry with name "+o.name)}this.topics(i)},s.prototype.handleTileSelect=function(e){var t=i.completeContent({title:e.name,url:e.url,targetProperties:{targetType:i.CONTENT_TARGET_WINDOW}});r.openContent(t)},s}));