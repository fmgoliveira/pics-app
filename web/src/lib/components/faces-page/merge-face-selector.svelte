<script lang="ts">
  import { createEventDispatcher, onMount } from 'svelte';
  import { api, type PersonResponseDto } from '@api';
  import FaceThumbnail from './face-thumbnail.svelte';
  import { quintOut } from 'svelte/easing';
  import { fly } from 'svelte/transition';
  import ControlAppBar from '../shared-components/control-app-bar.svelte';
  import Button from '../elements/buttons/button.svelte';
  import { flip } from 'svelte/animate';
  import { NotificationType, notificationController } from '../shared-components/notification/notification';
  import ConfirmDialogue from '../shared-components/confirm-dialogue.svelte';
  import { handleError } from '$lib/utils/handle-error';
  import { goto } from '$app/navigation';
  import { ActionQueryParameterValue, AppRoute, QueryParameter } from '$lib/constants';
  import { mdiCallMerge, mdiMerge, mdiSwapHorizontal } from '@mdi/js';
  import Icon from '$lib/components/elements/icon.svelte';
  import CircleIconButton from '../elements/buttons/circle-icon-button.svelte';
  import PeopleList from './people-list.svelte';
  import { page } from '$app/stores';

  export let person: PersonResponseDto;
  let people: PersonResponseDto[] = [];
  let selectedPeople: PersonResponseDto[] = [];
  let screenHeight: number;
  let isShowConfirmation = false;

  let dispatch = createEventDispatcher<{
    back: void;
    merge: PersonResponseDto;
  }>();

  $: hasSelection = selectedPeople.length > 0;
  $: unselectedPeople = people.filter(
    (source) => !selectedPeople.some((selected) => selected.id === source.id) && source.id !== person.id,
  );

  onMount(async () => {
    const { data } = await api.personApi.getAllPeople({ withHidden: false });
    people = data.people;
  });

  const onClose = () => {
    dispatch('back');
  };

  const handleSwapPeople = () => {
    [person, selectedPeople[0]] = [selectedPeople[0], person];
    $page.url.searchParams.set(QueryParameter.ACTION, ActionQueryParameterValue.MERGE);
    goto(`${AppRoute.PEOPLE}/${person.id}?${$page.url.searchParams.toString()}`);
  };

  const onSelect = (selected: PersonResponseDto) => {
    if (selectedPeople.includes(selected)) {
      selectedPeople = selectedPeople.filter((person) => person.id !== selected.id);
      return;
    }

    if (selectedPeople.length >= 5) {
      notificationController.show({
        message: 'You can only merge up to 5 faces at a time',
        type: NotificationType.Info,
      });
      return;
    }

    selectedPeople = [selected, ...selectedPeople];
  };

  const handleMerge = async () => {
    try {
      let { data: results } = await api.personApi.mergePerson({
        id: person.id,
        mergePersonDto: { ids: selectedPeople.map(({ id }) => id) },
      });
      const { data: mergedPerson } = await api.personApi.getPerson({ id: person.id });
      const count = results.filter(({ success }) => success).length;
      notificationController.show({
        message: `Merged ${count} ${count === 1 ? 'person' : 'people'}`,
        type: NotificationType.Info,
      });
      dispatch('merge', mergedPerson);
    } catch (error) {
      handleError(error, 'Cannot merge people');
    } finally {
      isShowConfirmation = false;
    }
  };
</script>

<svelte:window bind:innerHeight={screenHeight} />

<section
  transition:fly={{ y: 500, duration: 100, easing: quintOut }}
  class="absolute left-0 top-0 z-[9999] h-full w-full bg-immich-bg dark:bg-immich-dark-bg"
>
  <ControlAppBar on:close={onClose}>
    <svelte:fragment slot="leading">
      {#if hasSelection}
        Selected {selectedPeople.length}
      {:else}
        Merge people
      {/if}
      <div />
    </svelte:fragment>
    <svelte:fragment slot="trailing">
      <Button
        size={'sm'}
        disabled={!hasSelection}
        on:click={() => {
          isShowConfirmation = true;
        }}
      >
        <Icon path={mdiMerge} size={18} />
        <span class="ml-2"> Merge</span></Button
      >
    </svelte:fragment>
  </ControlAppBar>
  <section class="bg-immich-bg px-[70px] pt-[100px] dark:bg-immich-dark-bg">
    <section id="merge-face-selector relative">
      <div class="mb-10 h-[200px] place-content-center place-items-center">
        <p class="mb-4 text-center uppercase dark:text-white">Choose matching people to merge</p>

        <div class="grid grid-flow-col-dense place-content-center place-items-center gap-4">
          {#each selectedPeople as person (person.id)}
            <div animate:flip={{ duration: 250, easing: quintOut }}>
              <FaceThumbnail border circle {person} selectable thumbnailSize={120} on:click={() => onSelect(person)} />
            </div>
          {/each}

          {#if hasSelection}
            <div class="relative h-full">
              <div class="flex flex-col h-full justify-between">
                <div class="flex h-full items-center justify-center">
                  <Icon path={mdiCallMerge} size={48} class="rotate-90 dark:text-white" />
                </div>
                {#if selectedPeople.length === 1}
                  <div class="absolute bottom-2">
                    <CircleIconButton icon={mdiSwapHorizontal} size="24" on:click={handleSwapPeople} />
                  </div>
                {/if}
              </div>
            </div>
          {/if}
          <FaceThumbnail {person} border circle selectable={false} thumbnailSize={180} />
        </div>
      </div>

      <PeopleList
        people={unselectedPeople}
        peopleCopy={unselectedPeople}
        unselectedPeople={selectedPeople}
        {screenHeight}
        on:select={({ detail }) => onSelect(detail)}
      />
    </section>

    {#if isShowConfirmation}
      <ConfirmDialogue
        title="Merge people"
        confirmText="Merge"
        on:confirm={handleMerge}
        on:cancel={() => (isShowConfirmation = false)}
      >
        <svelte:fragment slot="prompt">
          <p>Are you sure you want merge these people ?</p></svelte:fragment
        >
      </ConfirmDialogue>
    {/if}
  </section>
</section>
