import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  const LoginRequested(this.username, this.password);
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserRepository _userRepository;
  UserModel? _currentUser;

  AuthBloc({required UserRepository userRepository}) 
      : _userRepository = userRepository,
        super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  UserModel? get currentUser => _currentUser;

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _userRepository.authenticate(event.username, event.password);
      if (user != null) {
        _currentUser = user;
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Invalid username or password'));
      }
    } catch (e) {
      emit(AuthError('Login failed: \$e'));
    }
  }

  void _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) {
    _currentUser = null;
    emit(AuthUnauthenticated());
  }

  void _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) {
    if (_currentUser != null) {
      emit(AuthAuthenticated(_currentUser!));
    } else {
      emit(AuthUnauthenticated());
    }
  }
}
