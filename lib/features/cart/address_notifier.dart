import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../data/reader_repository.dart';

final addressProvider = StateNotifierProvider<AddressNotifier, AsyncValue<List<Address>>>((ref) {
  final repo = ref.watch(readerRepositoryProvider);
  return AddressNotifier(repo)..load();
});

class AddressNotifier extends StateNotifier<AsyncValue<List<Address>>> {
  AddressNotifier(this._repo) : super(const AsyncValue.loading());

  final ReaderRepository _repo;

  Future<void> load() async {
    try {
      final list = await _repo.getAddresses();
      state = AsyncValue.data(list);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<Address> addAddress(Map<String, dynamic> data) async {
    final newAddress = await _repo.addAddress(data);
    
    state.whenData((list) {
      state = AsyncValue.data([newAddress, ...list]);
    });
    
    return newAddress;
  }
}
