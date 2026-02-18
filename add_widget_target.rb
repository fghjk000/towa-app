require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = File.join(__dir__, 'ios/Runner.xcodeproj')
APP_GROUP    = 'group.com.shiftwidget'
WIDGET_NAME  = 'ShiftWidget'
BUNDLE_ID    = 'com.shiftwidget.shiftWidgetApp.ShiftWidget'
DEPLOY_TARGET = '16.0'

project = Xcodeproj::Project.open(PROJECT_PATH)

# ─── 1. 이미 ShiftWidget 타겟이 있으면 건너뜀 ───────────────────────────────
if project.targets.any? { |t| t.name == WIDGET_NAME }
  puts "✅ #{WIDGET_NAME} 타겟이 이미 존재합니다. 건너뜁니다."
  exit 0
end

# ─── 2. Widget Extension 타겟 생성 ──────────────────────────────────────────
widget_target = project.new_target(
  :app_extension,
  WIDGET_NAME,
  :ios,
  DEPLOY_TARGET,
  project.products_group,
  :swift
)
puts "✅ 타겟 생성: #{WIDGET_NAME}"

# ─── 3. Build Settings 설정 ─────────────────────────────────────────────────
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']    = BUNDLE_ID
  config.build_settings['SWIFT_VERSION']                = '5.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']   = DEPLOY_TARGET
  config.build_settings['TARGETED_DEVICE_FAMILY']       = '1,2'
  config.build_settings['CODE_SIGN_ENTITLEMENTS']       = "ShiftWidget/ShiftWidget.entitlements"
  config.build_settings['INFOPLIST_FILE']               = "ShiftWidget/Info.plist"
  config.build_settings['SKIP_INSTALL']                 = 'YES'
  config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
end
puts "✅ Build Settings 구성"

# ─── 4. Swift 소스 파일 추가 ────────────────────────────────────────────────
widget_group = project.main_group.find_subpath('ShiftWidget') ||
               project.main_group.new_group('ShiftWidget', 'ShiftWidget')

swift_ref = widget_group.find_file_by_path('ShiftWidget.swift') ||
            widget_group.new_file('ShiftWidget/ShiftWidget.swift')

info_ref = widget_group.find_file_by_path('Info.plist') ||
           widget_group.new_file('ShiftWidget/Info.plist')

entitlements_ref = widget_group.find_file_by_path('ShiftWidget.entitlements') ||
                   widget_group.new_file('ShiftWidget/ShiftWidget.entitlements')

sources_phase = widget_target.source_build_phase
sources_phase.add_file_reference(swift_ref) unless
  sources_phase.files_references.include?(swift_ref)

resources_phase = widget_target.resources_build_phase
resources_phase.add_file_reference(info_ref) unless
  resources_phase.files_references.include?(info_ref)

puts "✅ 소스 파일 추가: ShiftWidget.swift, Info.plist"

# ─── 5. Runner가 ShiftWidget을 embed ────────────────────────────────────────
runner_target = project.targets.find { |t| t.name == 'Runner' }
if runner_target
  embed_phase = runner_target.build_phases.find { |p|
    p.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) &&
    p.name == 'Embed Foundation Extensions'
  }

  unless embed_phase
    embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
    embed_phase.name = 'Embed Foundation Extensions'
    embed_phase.dst_subfolder_spec = '13'  # Plugins (App Extensions)
    runner_target.build_phases << embed_phase
  end

  widget_product = widget_target.product_reference
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.file_ref = widget_product
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  embed_phase.files << build_file unless
    embed_phase.files.any? { |f| f.file_ref == widget_product }

  puts "✅ Runner에 Widget Extension Embed 설정"
end

# ─── 6. App Group Entitlement을 Runner에도 적용 ─────────────────────────────
runner_target&.build_configurations&.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] ||= 'Runner/Runner.entitlements'
end
puts "✅ Runner entitlements 경로 설정"

# ─── 7. 프로젝트 저장 ────────────────────────────────────────────────────────
project.save
puts ""
puts "🎉 project.pbxproj 저장 완료!"
puts ""
puts "⚠️  Xcode에서 아직 해야 할 작업:"
puts "  1. Runner 타겟 → Signing & Capabilities → + App Groups → #{APP_GROUP}"
puts "  2. ShiftWidget 타겟 → Signing & Capabilities → + App Groups → #{APP_GROUP}"
puts "  3. 두 타겟 모두 개발팀(Team) 선택"
