// encoding=utf-8
PRODUCT_NAME=BSSpotlighter
VERSION=1.3
REV_CORRECT=14
PRODUCT_EXTENSION=app
BUILD_PATH=./build
DEPLOYMENT=Release
APP_BUNDLE=$(PRODUCT_NAME).$(PRODUCT_EXTENSION)
APP=$(BUILD_PATH)/$(DEPLOYMENT)/$(APP_BUNDLE)
APP_NAME=$(BUILD_PATH)/$(DEPLOYMENT)/$(PRODUCT_NAME)
INFO_PLIST=Info.plist
COPYLIGHT=© copyright 2006-2008 by masakih

URL_BSSpotlighter = svn+ssh://macmini/usr/local/svnrepos/BSSpotlighter
HEAD = $(URL_BSSpotlighter)/BSSpotlighter
TAGS_DIR = $(URL_BSSpotlighter)/tags

all:
	@echo do  nothig.
	@echo use target tagging 

tagging: update_svn
	@echo "Tagging the $(VERSION) (x) release of BSSpotlighter project."
	REV=`LC_ALL=C svn info | awk '/Revision/ {print $$2}'` ;	\
	REV=`expr $$REV + $(REV_CORRECT)`	;	\
	echo svn copy $(HEAD) $(TAGS_DIR)/release-$(VERSION).$${REV}

release: updateRevision
	xcodebuild -configuration $(DEPLOYMENT)
	$(MAKE) restorInfoPlist

package: release
	REV=`LC_ALL=C svn info | awk '/Revision/ {print $$2}'`;	\
	REV=`expr $$REV + $(REV_CORRECT)`	;	\
	ditto -ck -rsrc --keepParent $(APP) $(APP_NAME)-$(VERSION)-$${REV}.zip

Info.plist: Info.plist.template
	sed -e "s/%%RELEASE%%/$(VERSION)/" -e "s/%%COPYLIGHT%%/$(COPYLIGHT)/" $< > $@

updateRevision: Info.plist update_svn
	if [ ! -f $(INFO_PLIST).bak ] ; then cp $(INFO_PLIST) $(INFO_PLIST).bak ; fi ;	\
	REV=`LC_ALL=C svn info | awk '/Revision/ {print $$2}'` ;	\
	REV=`expr $$REV + $(REV_CORRECT)`	;	\
	sed -e "s/%%%%REVISION%%%%/$${REV}/" $(INFO_PLIST) > $(INFO_PLIST).r ;	\
	mv -f $(INFO_PLIST).r $(INFO_PLIST) ;

restorInfoPlist:
	if [ -f $(INFO_PLIST).bak ] ; then cp -f $(INFO_PLIST).bak $(INFO_PLIST) ; fi

update_svn:
	svn up
