# frozen_string_literal: true

# migrationエラー
class InvalidMigrationError < CustomError
  http_status :unauthorized
  code 'invalid_migration_error'
end
