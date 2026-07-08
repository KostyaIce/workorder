[app]
title = WorkOrder
project_dir = ..
input_file = main.py
main_file = main.py
exec_directory = ..
icon = ../resources/icons/appIcons/icon_linux.png

[python]
python_path = /home/kostya/.local/python311/bin/python3.11
packages = 
android_packages = buildozer==1.5.0,cython==0.29.33

[qt]
qml_files = resources/qml/WorkOrder/Common/Card.qml,resources/qml/WorkOrder/Common/ClientFormDialog.qml,resources/qml/WorkOrder/Common/CoefficientSearchField.qml,resources/qml/WorkOrder/Common/ConfirmDialog.qml,resources/qml/WorkOrder/Common/DatabaseContent.qml,resources/qml/WorkOrder/Common/DividerLine.qml,resources/qml/WorkOrder/Common/EditablePriceLabel.qml,resources/qml/WorkOrder/Common/FormField.qml,resources/qml/WorkOrder/Common/FormFieldRow.qml,resources/qml/WorkOrder/Common/FormTextArea.qml,resources/qml/WorkOrder/Common/InvoiceClientField.qml,resources/qml/WorkOrder/Common/InvoiceFormContent.qml,resources/qml/WorkOrder/Common/InvoiceLinesList.qml,resources/qml/WorkOrder/Common/InvoiceWorksDialog.qml,resources/qml/WorkOrder/Common/InvoiceWorksListContent.qml,resources/qml/WorkOrder/Common/ObjectDialog.qml,resources/qml/WorkOrder/Common/OverlaySearchSuggestions.qml,resources/qml/WorkOrder/Common/PageHeader.qml,resources/qml/WorkOrder/Common/PrimaryButton.qml,resources/qml/WorkOrder/Common/QuantityField.qml,resources/qml/WorkOrder/Common/ReportOptionCheckRow.qml,resources/qml/WorkOrder/Common/ReportOptionsDialog.qml,resources/qml/WorkOrder/Common/ReportResultDialog.qml,resources/qml/WorkOrder/Common/ReportsContent.qml,resources/qml/WorkOrder/Common/SelectedServicePanel.qml,resources/qml/WorkOrder/Common/SelectionDialog.qml,resources/qml/WorkOrder/Common/ServiceDeleteDialog.qml,resources/qml/WorkOrder/Common/ServiceDialog.qml,resources/qml/WorkOrder/Common/ServiceFormDialog.qml,resources/qml/WorkOrder/Common/ServiceNameText.qml,resources/qml/WorkOrder/Common/ServiceSearchField.qml,resources/qml/WorkOrder/Common/SettingsAboutSection.qml,resources/qml/WorkOrder/Common/SettingsActionRow.qml,resources/qml/WorkOrder/Common/SettingsContent.qml,resources/qml/WorkOrder/Common/SettingsFormRow.qml,resources/qml/WorkOrder/Common/SettingsListItem.qml,resources/qml/WorkOrder/Common/SettingsSection.qml,resources/qml/WorkOrder/Common/SettingsToggleRow.qml,resources/qml/WorkOrder/Common/SubobjectSearchField.qml,resources/qml/WorkOrder/Common/TotalPanel.qml,resources/qml/WorkOrder/Common/WorkFormDialog.qml,resources/qml/WorkOrder/Common/WorkOrderComboBox.qml,resources/qml/desktop/DatabasePage.qml,resources/qml/desktop/InvoicePage.qml,resources/qml/desktop/ReportsPage.qml,resources/qml/desktop/SettingsPage.qml,resources/qml/desktop/main.qml,resources/qml/mobile/DatabasePage.qml,resources/qml/mobile/InvoicePage.qml,resources/qml/mobile/ReportsPage.qml,resources/qml/mobile/SettingsPage.qml,resources/qml/mobile/main.qml
excluded_qml_plugins = QtCharts,QtSensors,QtWebEngine
modules = Core,Network,Gui,Qml,OpenGL,QuickControls2,Quick
plugins = 

[android]
wheel_pyside = /home/kostya/Project/pyside-setup/dist/PySide6-6.8.0-6.8.3-cp311-cp311-android_aarch64.whl
wheel_shiboken = /home/kostya/Project/pyside-setup/dist/shiboken6-6.8.0-6.8.3-cp311-cp311-android_aarch64.whl
plugins = platforms_qtforandroid

[buildozer]
mode = debug
recipe_dir = /home/kostya/Project/WorkOrder/workorder/android/deployment/recipes
jars_dir = /home/kostya/Project/WorkOrder/workorder/android/deployment/jar/PySide6/jar
ndk_path = /home/kostya/Android/Sdk/ndk/26.1.10909125
sdk_path = /home/kostya/Android/Sdk
local_libs = plugins_platforms_qtforandroid
arch = arm64-v8a

