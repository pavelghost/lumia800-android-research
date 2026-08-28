LOCAL_PATH := device/nokia/lumia800

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/init.lumia800.rc:root/init.lumia800.rc \
    $(LOCAL_PATH)/rootdir/init.lumia800.usb.rc:root/init.lumia800.usb.rc \
    $(LOCAL_PATH)/rootdir/ueventd.lumia800.rc:root/ueventd.lumia800.rc

PRODUCT_PACKAGES += \
    adbd \
    toolbox \
    toybox

PRODUCT_PROPERTY_OVERRIDES += \
    ro.secure=0 \
    ro.adb.secure=0 \
    ro.debuggable=1 \
    persist.sys.usb.config=adb \
    ro.sf.lcd_density=240
