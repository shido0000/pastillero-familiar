// Ajustes de accesibilidad, tema y estado de la app (SharedPreferences).
// Pensados para adultos mayores: texto grande y alto contraste de fábrica.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ModoTema { sistema, claro, oscuro }

class AjustesState {
  final ModoTema modoTema;
  final bool textoGrande;
  final bool altoContraste;
  final bool onboardingCompleto;
  final int? perfilActivoId; // último perfil seleccionado

  const AjustesState({
    this.modoTema = ModoTema.sistema,
    this.textoGrande = false,
    this.altoContraste = false,
    this.onboardingCompleto = false,
    this.perfilActivoId,
  });

  AjustesState copyWith({
    ModoTema? modoTema,
    bool? textoGrande,
    bool? altoContraste,
    bool? onboardingCompleto,
    ValueGetter<int?>? perfilActivoId, // permite asignar null
  }) =>
      AjustesState(
        modoTema: modoTema ?? this.modoTema,
        textoGrande: textoGrande ?? this.textoGrande,
        altoContraste: altoContraste ?? this.altoContraste,
        onboardingCompleto: onboardingCompleto ?? this.onboardingCompleto,
        perfilActivoId: perfilActivoId != null ? perfilActivoId() : this.perfilActivoId,
      );
}

class AjustesController extends AsyncNotifier<AjustesState> {
  late SharedPreferences _prefs;

  @override
  Future<AjustesState> build() async {
    _prefs = await SharedPreferences.getInstance();
    return AjustesState(
      modoTema: ModoTema.values[_prefs.getInt('modoTema') ?? 0],
      textoGrande: _prefs.getBool('textoGrande') ?? false,
      altoContraste: _prefs.getBool('altoContraste') ?? false,
      onboardingCompleto: _prefs.getBool('onboardingCompleto') ?? false,
      perfilActivoId: _prefs.getInt('perfilActivoId'),
    );
  }

  Future<void> setModoTema(ModoTema modo) async {
    await _prefs.setInt('modoTema', modo.index);
    state = AsyncData(state.requireValue.copyWith(modoTema: modo));
  }

  Future<void> setTextoGrande(bool valor) async {
    await _prefs.setBool('textoGrande', valor);
    state = AsyncData(state.requireValue.copyWith(textoGrande: valor));
  }

  Future<void> setAltoContraste(bool valor) async {
    await _prefs.setBool('altoContraste', valor);
    state = AsyncData(state.requireValue.copyWith(altoContraste: valor));
  }

  Future<void> setOnboardingCompleto() async {
    await _prefs.setBool('onboardingCompleto', true);
    state = AsyncData(state.requireValue.copyWith(onboardingCompleto: true));
  }

  Future<void> setPerfilActivo(int? id) async {
    if (id == null) {
      await _prefs.remove('perfilActivoId');
    } else {
      await _prefs.setInt('perfilActivoId', id);
    }
    state = AsyncData(state.requireValue.copyWith(perfilActivoId: () => id));
  }
}

final ajustesProvider =
    AsyncNotifierProvider<AjustesController, AjustesState>(AjustesController.new);
