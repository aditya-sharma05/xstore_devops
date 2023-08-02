define(["ojs/ojcore","knockout","jraf/utils/ValidationUtils","jraf/models/UIShellManager","jraf/controllers/LayoutManager","ojs/ojmodule-element-utils","ojs/ojmodule-element","ojs/ojknockout","ojs/ojcomposite","jraf/composites/oj-rgbu-jraf-message-dialog/loader","ojs/ojinputtext","ojs/ojbutton","ojs/ojlabel"],(function(o,t,e,i,n,s){"use strict";var r=o.Translations.getTranslatedString;function a(i){if(!e.isObjectStrict(i)||!e.isFunction(i.getLoginHandlerCallback))throw new TypeError("Login: Invalid param(s).");var n=this,a=e.isNonemptyString(i.fromCopyrightYear)?i.fromCopyrightYear:"xxxx",l=e.isNonemptyString(i.toCopyrightYear)?i.toCopyrightYear:"xxxx";this.headerText=r("jraf.login.loginHeader"),this.userIdLabel=r("xenv.login.userName"),this.passwordLabel=r("xenv.login.password"),this.loginErrorMessage=r("jraf.login.loginErrorMessage"),this.loginLabel=r("jraf.login.login"),this.okButtonLabel=r("jraf.common.ok"),this.copyrightStatement=r("jraf.login.copyright",{fromYear:a,toYear:l}),this.trademarksStatement=r("jraf.login.trademarks"),this.versionInfo="Xenvironment 22.0.0.0.20230127185818, TS 00000",n.statusConfig=s.createConfig({name:"status",params:{}}),this._layoutMonitor=o.ResponsiveKnockoutUtils.createScreenRangeObservable(),this.isMobileLayout=t.pureComputed((function(){return this._layoutMonitor()===o.ResponsiveUtils.SCREEN_RANGE.SM}),this),this.layoutFlexClasses=t.pureComputed((function(){return this.isMobileLayout()?"oj-flex":"oj-flex-bar oj-flex-items-pad"}),this),this.layoutFlexItemClasses=t.pureComputed((function(){return this.isMobileLayout()?"oj-flex-item":"oj-flex-bar-end"}),this),this.mobileLayoutInputtext=t.pureComputed((function(){return this.isMobileLayout()?"jraf-mobile-login-inputext":{}}),this),this.mobileLayoutButton=t.pureComputed((function(){return this.isMobileLayout()?"jraf-mobile-login-button":{}}),this),this.userName=t.observable(""),this.pwd=t.observable(""),this.handlingLogin=t.observable(!1),this.loginHandler=i.getLoginHandlerCallback,this.processLogin=function(o){n._handleLogin(o)},this.dismissDialog=function(){n._dismissDialog()},this.onSubmit=function(o){n._onSubmit(o)}}return a.prototype._onSubmit=function(o){o.preventDefault()},a.prototype._handleLogin=function(){o.Logger.info("Login._handleLogin: Entering.");var t=this;document.getElementById("uid").blur(),document.getElementById("pwd").blur(),i.startProcessingIndicator(),this.handlingLogin(!0),this.loginHandler(this.userName(),this.pwd()).then((function(){t._handleLoginSuccess()})).catch((function(){t._handleLoginFailure()}))},a.prototype._handleLoginLoadingComplete=function(){i.stopProcessingIndicator(),this.handlingLogin(!1)},a.prototype._handleLoginSuccess=function(){o.Logger.info("Login._handleLoginSuccess: Entering."),this._handleLoginLoadingComplete(),o.Router.rootInstance.go("Home")},a.prototype._handleLoginFailure=function(){o.Logger.info("Login._handleLoginFailure: Entering."),this._handleLoginLoadingComplete(),this._getDialog().open()},a.prototype._getDialog=function(){return document.getElementById("jraf-login-failed-dialog")},a}));