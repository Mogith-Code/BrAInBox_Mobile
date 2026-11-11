import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/users_models.dart';

part 'users_repository.g.dart';

/// Students (admin). Only this layer calls the API.
abstract interface class UsersRepository {
  /// `GET /admin/users?search=&exam_year=&status=&district=`
  Future<StudentPage> students(StudentFilter filter);

  /// `PATCH /admin/users/{id}` with `{is_active}`: suspend (false) or
  /// reinstate (true). Returns the updated row.
  Future<AdminStudent> setActive(String id, {required bool active});
}

class ApiUsersRepository implements UsersRepository {
  ApiUsersRepository(this.api);

  final ApiClient api;

  @override
  Future<StudentPage> students(StudentFilter filter) async =>
      StudentPage.fromJson(
        await api.get<Map<String, dynamic>>(
          '/admin/users',
          query: filter.toQuery(),
        ),
      );

  @override
  Future<AdminStudent> setActive(String id, {required bool active}) async =>
      AdminStudent.fromJson(
        await api.patch<Map<String, dynamic>>(
          '/admin/users/$id',
          data: {'is_active': active},
        ),
      );
}

/// DEBUG ONLY (`USE_FAKE_API=true`): the students from the Figma page.
class FakeUsersRepository implements UsersRepository {
  final _rows = <AdminStudent>[
    for (final (id, name, email, school, district, year, mastery, status, ago)
        in _sample)
      AdminStudent(
        id: id,
        fullName: name,
        email: email,
        school: school,
        district: district,
        examYear: year,
        avgMastery: mastery,
        status: status,
        lastActiveAt: DateTime.now().subtract(ago),
      ),
  ];

  static const _sample = [
    (
      'u1',
      'Nethmi Perera',
      'nethmi.p@gmail.com',
      'Visakha V.',
      'Colombo',
      2027,
      74,
      StudentStatus.active,
      Duration(minutes: 2),
    ),
    (
      'u2',
      'Kavindu Silva',
      'kavindu22@gmail.com',
      'Trinity C.',
      'Kandy',
      2027,
      58,
      StudentStatus.active,
      Duration(hours: 1),
    ),
    (
      'u3',
      'Sanduni Fernando',
      'sanduni.f@yahoo.com',
      'Southlands',
      'Galle',
      2026,
      81,
      StudentStatus.active,
      Duration(hours: 5),
    ),
    (
      'u4',
      'Ruwan Jayasinghe',
      'ruwan.bio@gmail.com',
      'Maliyadeva',
      'Kurunegala',
      2027,
      42,
      StudentStatus.suspended,
      Duration(days: 6),
    ),
    (
      'u5',
      'Ishara Kumari',
      'ishara.k@gmail.com',
      'Vembadi',
      'Jaffna',
      2027,
      66,
      StudentStatus.active,
      Duration(days: 1),
    ),
    (
      'u6',
      'Tharindu Bandara',
      't.bandara@gmail.com',
      'Rahula C.',
      'Matara',
      2026,
      31,
      StudentStatus.inactive,
      Duration(days: 34),
    ),
    (
      'u7',
      'Amaya Wickramasinghe',
      'amaya.w@gmail.com',
      'Ladies C.',
      'Colombo',
      2027,
      88,
      StudentStatus.active,
      Duration(hours: 3),
    ),
    (
      'u8',
      'Dineth Rajapaksha',
      'dineth.r@gmail.com',
      'Maris Stella',
      'Negombo',
      2027,
      53,
      StudentStatus.active,
      Duration(hours: 6),
    ),
  ];

  @override
  Future<StudentPage> students(StudentFilter filter) async {
    final q = filter.search.trim().toLowerCase();
    final items = _rows.where((s) {
      if (filter.examYear != null && s.examYear != filter.examYear) {
        return false;
      }
      if (filter.status != null && s.status != filter.status) return false;
      if (filter.district != null && s.district != filter.district) {
        return false;
      }
      return q.isEmpty ||
          '${s.fullName} ${s.email} ${s.school}'.toLowerCase().contains(q);
    }).toList();
    return StudentPage(items: items, total: 3105, activeTotal: 2418);
  }

  @override
  Future<AdminStudent> setActive(String id, {required bool active}) async {
    final i = _rows.indexWhere((s) => s.id == id);
    _rows[i] = _rows[i].copyWith(
      status: active ? StudentStatus.active : StudentStatus.suspended,
    );
    return _rows[i];
  }
}

@Riverpod(keepAlive: true)
UsersRepository usersRepository(Ref ref) => Env.useFakeApi
    ? FakeUsersRepository()
    : ApiUsersRepository(ref.watch(apiClientProvider));
