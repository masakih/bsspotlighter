// encoding=utf-8
PRODUCT_NAME=BSSpotlighter
VERSION=1.3
PRODUCT_EXTENSION=app
BUILD_PATH=./build
DEPLOYMENT=Release
APP_BUNDLE=$(PRODUCT_NAME).$(PRODUCT_EXTENSION)
APP=$(BUILD_PATH)/$(DEPLOYMENT)/$(APP_BUNDLE)
APP_NAME=$(BUILD_PATH)/$(DEPLOYMENT)/$(PRODUCT_NAME)
INFO_PLIST=Info.plist
COPYLIGHT=© copyright 2006-2007 by masakih

URL_BSSpotlighter = svn+ssh://macminiwireless/usr/local/svnrepos/BSSpotlighter
HEAD = $(URL_BSSpotlighter)/BSSpotlighter
TAGS_DIR = $(URL_BSSpotlighter)/tags

all:
	@echo do  nothig.
	@echo use target tagging 

tagging:
	@echo "Tagging the $(VERSION) (x) release of BSSpotlighter project."
	REV=`LC_ALL=C svn info | awk '/Revision/ {print $$2}'` ;	\
	echo svn copy $(HEAD) $(TAGS_DIR)/release-$(VERSION).$${REV}

release: updateRevision
	xcodebuild -configuration $(DEPLOYMENT)
	$(MAKE) restorInfoPlist

package: release
	REV=`LC_ALL=C svn info | awk '/Revision/ {print $$2}'`;	\
	ditto -ck -rsrc --keepParent $(APP) $(APP_NAME)-$(VERSION)-$${REV}.zip

Info.plist: Info.plist.template
	sed -e "s/%%RELEASE%%/$(VERSION)/" -e "s/%%COPYLIGHT%%/$(COPYLIGHT)/" $< > $@

updateRevision: update_svn Info.plist
	if [ ! -f $(INFO_PLIST).bak ] ; then cp $(INFO_PLIST) $(INFO_PLIST).bak ; fi ;	\
	REV=`LC_ALL=C svn info | awk '/Revision/ {print $$2}'` ;	\
	sed -e "s/%%%%REVISION%%%%/$${REV}/" $(INFO_PLIST) > $(INFO_PLIST).r ;	\
	mv -f $(INFO_PLIST).r $(INFO_PLIST) ;

restorInfoPlist:
	if [ -f $(INFO_PLIST).bak ] ; then cp -f $(INFO_PLIST).bak $(INFO_PLIST) ; fi

update_svn:
	svn up
