$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, device/nokia/lumia800/device.mk)
$(call inherit-product, vendor/cm/config/common_mini_phone.mk)

PRODUCT_NAME := cm_lumia800
PRODUCT_DEVICE := lumia800
PRODUCT_BRAND := Nokia
PRODUCT_MODEL := Lumia 800
PRODUCT_MANUFACTURER := Nokia
PRODUCT_CHARACTERISTICS := phone

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=lumia800 \
    TARGET_DEVICE=lumia800

TARGET_UNOFFICIAL_BUILD_ID := Lumia800Bringup
