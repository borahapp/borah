import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/cards/restaurant_card.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/inputs/app_search_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../restaurants/domain/restaurant.dart';
import '../../application/create_event_controller.dart';
import '../../application/event_restaurant_search_controller.dart';
import '../../application/events_list_controller.dart';
import '../states/create_event_status.dart';
import '../states/event_restaurant_search_status.dart';

/// Tela de criação de rolê (ROLÊ-02) - página única, dividida
/// visualmente em 2 etapas (buscar/selecionar restaurante; escolher
/// data/hora). Sem confirmação de presença, fotos, lista ou detalhe -
/// fora do escopo desta sprint. Nenhuma regra de negócio aqui: só
/// coleta os 3 valores e chama `create_event()` via
/// `CreateEventController`.
///
/// UX-01: quando a busca não encontra o restaurante, oferece cadastrá-lo
/// sem sair deste fluxo (`_createRestaurant`) - fecha o beco sem saída
/// que antes exigia cancelar a criação do rolê inteira.
class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  final _searchController = TextEditingController();

  /// 0 = buscar/selecionar restaurante; 1 = data/hora.
  int _step = 0;
  Restaurant? _selectedRestaurant;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    ref
        .read(eventRestaurantSearchControllerProvider.notifier)
        .search(_searchController.text);
  }

  void _selectRestaurant(Restaurant restaurant) {
    setState(() => _selectedRestaurant = restaurant);
  }

  void _changeRestaurant() {
    setState(() => _selectedRestaurant = null);
  }

  /// UX-01: a busca não encontrar o restaurante era um beco sem saída
  /// (cancelar a criação do rolê, ir para a aba Restaurantes, cadastrar,
  /// voltar e refazer tudo do início). `extra: true` sinaliza para
  /// `CreateRestaurantPage` devolver (`context.pop(next.restaurant)`) o
  /// restaurante recém-criado em vez de ir para o Detalhe dele (mesmo
  /// mecanismo de `extra` já usado em `_editGroup`/`_shareInviteCode`,
  /// não um padrão novo). Selecionar direto o `Restaurant` devolvido -
  /// em vez de refazer a busca e esperar o usuário tocar no resultado -
  /// é mais simples, não só melhor UX: evita depender de o texto
  /// buscado antes bater com o nome cadastrado, e evita uma consulta
  /// totalmente evitável (o objeto já está em memória). Nenhum outro
  /// estado desta tela (grupo, etapa) se perde - `push` mantém
  /// `CreateEventPage` montada por baixo, sem recriar o `State`.
  Future<void> _createRestaurant() async {
    final restaurant = await context.push<Restaurant>(
      '/restaurants/new',
      extra: true,
    );
    if (!mounted || restaurant == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Restaurante cadastrado.')));
    setState(() => _selectedRestaurant = restaurant);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() {
      _selectedDate = date;
      // Fluxo obrigatório data -> hora: trocar a data invalida a hora
      // já escolhida, para nunca combinar data nova com hora antiga.
      _selectedTime = null;
    });
  }

  Future<void> _pickTime() async {
    if (_selectedDate == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() => _selectedTime = time);
  }

  /// Evita repetir os mesmos 5 campos do `Restaurant` nos 3 pontos desta
  /// tela que exibem um `RestaurantCard` (resultado da busca, resumo na
  /// etapa 1 após selecionar, resumo na etapa 2).
  Widget _restaurantCard(Restaurant restaurant, {VoidCallback? onTap}) {
    return RestaurantCard(
      name: restaurant.name,
      category: restaurant.category,
      city: restaurant.city,
      rating: restaurant.averageRating,
      reviewCount: restaurant.totalReviews,
      onTap: onTap,
    );
  }

  void _create() {
    final restaurant = _selectedRestaurant;
    final date = _selectedDate;
    final time = _selectedTime;
    if (restaurant == null || date == null || time == null) return;

    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    ref
        .read(createEventControllerProvider.notifier)
        .create(
          groupId: widget.groupId,
          restaurantId: restaurant.id,
          scheduledAt: scheduledAt,
        );
  }

  @override
  Widget build(BuildContext context) {
    final createStatus = ref.watch(createEventControllerProvider);
    final isCreating = createStatus is CreateEventSaving;

    ref.listen<CreateEventStatus>(createEventControllerProvider, (
      previous,
      next,
    ) {
      if (next is CreateEventError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      } else if (next is CreateEventSaveSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rolê criado com sucesso.')),
        );
        // RC-02D: `EventsListPage._createEvent` recarrega via
        // `await context.push(...)` + checagem de `mounted` ao retornar -
        // mas o `PopScope` de 2 etapas desta tela intercepta o primeiro
        // `context.pop()` quando `_step == 1` (fecha a Etapa 2 de volta
        // para a Etapa 1 em vez de sair da rota), então o `Future`
        // aguardado do outro lado nunca resolve no momento esperado e o
        // reload silenciosamente não roda. Recarregar direto aqui, antes
        // do pop, independe desse timing.
        ref.read(eventsListControllerProvider.notifier).load(widget.groupId);
        context.pop();
      }
    });

    // Achado de QA (BLOCO 9): sem isto, o botão de voltar padrão do
    // `AppBar` (e o gesto/botão de voltar do sistema) saía da tela
    // inteira a partir da Etapa 2, descartando o restaurante já
    // selecionado - não havia como voltar para a Etapa 1 para trocar de
    // restaurante sem recomeçar o fluxo do zero. `_step` é estado local
    // (não é uma rota própria), então o pop padrão do Navigator não
    // sabia decrementá-lo.
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _step = 0);
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: 'Criar rolê',
          leading: _step == 0
              ? null
              : AppIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Voltar',
                  onPressed: () => setState(() => _step = 0),
                ),
        ),
        body: SafeArea(
          child: _step == 0 ? _buildStep1() : _buildStep2(isCreating),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    final searchStatus = ref.watch(eventRestaurantSearchControllerProvider);
    final selected = _selectedRestaurant;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selected == null) ...[
            AppSearchField(
              controller: _searchController,
              label: 'Buscar restaurante',
              onSubmit: (_) => _search(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _buildSearchResults(searchStatus)),
          ] else ...[
            _restaurantCard(selected),
            const SizedBox(height: AppSpacing.md),
            AppOutlinedButton(
              label: 'Trocar restaurante',
              onPressed: _changeRestaurant,
            ),
            const Spacer(),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Continuar',
            onPressed: selected == null
                ? null
                : () => setState(() => _step = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(EventRestaurantSearchStatus status) {
    return switch (status) {
      EventRestaurantSearchInitial() => const SizedBox.shrink(),
      EventRestaurantSearchLoading() => const LoadingScreen(
        key: ValueKey('loading'),
      ),
      EventRestaurantSearchError(:final message) => ErrorState(
        key: const ValueKey('error'),
        message: message,
        onRetry: _search,
      ),
      EventRestaurantSearchEmpty() => Center(
        key: const ValueKey('empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nenhum restaurante encontrado.'),
            const SizedBox(height: AppSpacing.md),
            AppOutlinedButton(
              label: 'Cadastrar restaurante',
              onPressed: _createRestaurant,
            ),
          ],
        ),
      ),
      EventRestaurantSearchLoaded(:final restaurants) => ListView.builder(
        key: const ValueKey('loaded'),
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _restaurantCard(
              restaurant,
              onTap: () => _selectRestaurant(restaurant),
            ),
          );
        },
      ),
    };
  }

  Widget _buildStep2(bool isCreating) {
    final selected = _selectedRestaurant!;
    final canCreate = _selectedDate != null && _selectedTime != null;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _restaurantCard(selected),
          const SizedBox(height: AppSpacing.xl),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Data'),
            subtitle: Text(
              _selectedDate == null
                  ? 'Selecionar data'
                  : '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                        '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                        '${_selectedDate!.year}',
            ),
            onTap: _pickDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time_outlined),
            title: const Text('Hora'),
            subtitle: Text(
              _selectedTime == null
                  ? 'Selecionar hora'
                  : _selectedTime!.format(context),
            ),
            // Fluxo obrigatório: hora só é selecionável depois da data.
            onTap: _selectedDate == null ? null : _pickTime,
            enabled: _selectedDate != null,
          ),
          const Spacer(),
          AppPrimaryButton(
            label: 'Criar rolê',
            isLoading: isCreating,
            onPressed: canCreate ? _create : null,
          ),
        ],
      ),
    );
  }
}
