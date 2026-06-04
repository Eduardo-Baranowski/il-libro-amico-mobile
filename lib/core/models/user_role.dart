enum UserRole { admin, editor, leitor }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.admin => 'Administrador',
        UserRole.editor => 'Editor',
        UserRole.leitor => 'Leitor',
      };

  static UserRole? tryParse(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'editor':
        return UserRole.editor;
      case 'leitor':
        return UserRole.leitor;
      default:
        return null;
    }
  }
}
