<template>
  <div>
    <div
      class="pa-3 d-flex"
      v-if="navMode === `MIXED`"
      :class="$vuetify.theme.dark ? `grey darken-5` : `blue darken-3`"
    >
      <v-btn
        depressed="depressed"
        :color="$vuetify.theme.dark ? `grey darken-4` : `blue darken-2`"
        style="min-width:0;"
        @click="goHome"
        :aria-label="$t(`common:header.home`)"
      >
        <v-icon size="20">mdi-home</v-icon>
      </v-btn>
      <v-btn
        class="ml-3"
        v-if="currentMode === `custom`"
        depressed="depressed"
        :color="$vuetify.theme.dark ? `grey darken-4` : `blue darken-2`"
        style="flex: 1 1 100%;"
        @click="switchMode(`browse`)"
      >
        <v-icon left="left">mdi-file-tree</v-icon>
        <div class="body-2 text-none">{{$t('common:sidebar.browse')}}</div>
      </v-btn>
      <v-btn
        class="ml-3"
        v-else-if="currentMode === `browse`"
        depressed="depressed"
        :color="$vuetify.theme.dark ? `grey darken-4` : `blue darken-2`"
        style="flex: 1 1 100%;"
        @click="switchMode(`custom`)"
      >
        <v-icon left="left">mdi-navigation</v-icon>
        <div class="body-2 text-none">{{$t('common:sidebar.mainMenu')}}</div>
      </v-btn>
    </div>

    <v-divider></v-divider>
    <v-list class="py-2" v-if="currentMode === `custom`" dense="dense" :class="color" :dark="dark">
      <template v-for="item of items">
        <v-list-item
          v-if="item.k === `link`"
          :href="item.t"
          :target="item.y === `externalblank` ? `_blank` : `_self`"
          :rel="item.y === `externalblank` ? `noopener` : ``"
        >
          <v-list-item-avatar size="24" tile="tile">
            <v-icon v-if="item.c.match(/fa[a-z] fa-/)" size="19">{{ item.c }}</v-icon>
            <v-icon v-else>{{ item.c }}</v-icon>
          </v-list-item-avatar>
          <v-list-item-title>{{ item.l }}</v-list-item-title>
        </v-list-item>
        <v-divider class="my-2" v-else-if="item.k === `divider`"></v-divider>
        <v-subheader class="pl-4" v-else-if="item.k === `header`">{{ item.l }}</v-subheader>
      </template>
    </v-list>
    <v-list
      class="py-2"
      v-else-if="currentMode === `browse`"
      dense="dense"
      :class="color"
      :dark="dark"
    >
      <template v-for="item of pageTree['home']">
        <nav-tree-item :item="item" :pageTree="pageTree" @expand="fetchBrowseItems" />
      </template>
    </v-list>
  </div>
</template>

<script>
import _ from "lodash";
import gql from "graphql-tag";
import { get } from "vuex-pathify";

import NavTreeItem from "./nav-tree-item";

/* global siteLangs */

export default {
  components: { NavTreeItem },

  props: {
    color: {
      type: String,
      default: "primary",
    },
    dark: {
      type: Boolean,
      default: true,
    },
    items: {
      type: Array,
      default: () => [],
    },
    navMode: {
      type: String,
      default: "MIXED",
    },
  },
  data() {
    return {
      currentMode: "custom",

      pageTree: {},
      rootItems: [],

      loadedCache: [],
    };
  },
  computed: {
    path: get("page/path"),
    locale: get("page/locale"),
  },
  methods: {
    switchMode(mode) {
      this.currentMode = mode;
      window.localStorage.setItem("navPref", mode);
      if (mode === `browse` && this.loadedCache.length < 1) {
        this.loadRootElements();
      }
    },
    async fetchBrowseItems(item) {
      if (this.pageTree[item.id]) return;

      const resp = await this.$apollo.query({
        query: gql`
          query($parent: Int, $locale: String!) {
            pages {
              tree(parent: $parent, mode: ALL, locale: $locale) {
                id
                path
                title
                isFolder
                pageId
                parent
                locale
              }
            }
          }
        `,
        fetchPolicy: "cache-first",
        variables: {
          parent: item.id,
          locale: this.locale,
        },
      });

      const items = _.get(resp, "data.pages.tree", []);
      this.$set(this.pageTree, item.id, items);

      for (const item of items) {
        if (item.isFolder) await this.fetchBrowseItems(item);
      }
    },
    async loadRootElements() {
      this.$store.commit(`loadingStart`, "browse-load");
      const resp = await this.$apollo.query({
        query: gql`
          query($path: String, $locale: String!) {
            pages {
              tree(
                path: $path
                mode: ALL
                locale: $locale
                includeAncestors: true
              ) {
                id
                path
                title
                isFolder
                pageId
                parent
                locale
              }
            }
          }
        `,
        fetchPolicy: "cache-first",
        variables: {
          path: "home",
          locale: this.locale,
        },
      });
      const items = _.get(resp, "data.pages.tree", []);

      for (const item of items) {
        if (item.isFolder) await this.fetchBrowseItems(item);
      }

      this.$set(this.pageTree, "home", items);
      this.$store.commit(`loadingStop`, "browse-load");
    },
    goHome() {
      window.location.assign(
        siteLangs.length > 0 ? `/${this.locale}/home` : "/"
      );
    },
  },
  mounted() {
    // this.currentParent.title = `/ ${this.$t("common:sidebar.root")}`;

    if (this.navMode === "TREE") {
      this.currentMode = "browse";
    } else if (this.navMode === "STATIC") {
      this.currentMode = "custom";
    } else {
      this.currentMode = window.localStorage.getItem("navPref") || "custom";
    }
    if (this.currentMode === "browse") {
      this.loadRootElements();
    }
  },
};
</script>
