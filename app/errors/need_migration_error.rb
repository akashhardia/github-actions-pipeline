# frozen_string_literal: true

# migrationが必須エラー
class NeedMigrationError < CustomError
  http_status :unauthorized
  code 'need_migration_error'
end
