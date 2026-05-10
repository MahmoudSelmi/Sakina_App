import 'package:flutter_bloc/flutter_bloc.dart';
part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  void loadHomeData() {
    emit(HomeLoading());
    // Simulate loading data
    Future.delayed(const Duration(seconds: 1), () {
      emit(HomeSuccess());
    });
  }
}
