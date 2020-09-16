<template>
  <div>
    <span
      class="sub-tree-item"
      :class="item.path == path ? 'sub-tree-highlight' : ''"
      @click="onClick"
    >
      <v-icon v-if="item.isFolder && open" size="19">mdi-chevron-down</v-icon>
      <v-icon v-if="item.isFolder && !open" size="19">mdi-chevron-right</v-icon>
      {{item.title}}
    </span>
    <span class="sub-tree" v-if="open && pageTree[item.id]">
      <nav-tree-item
        v-for="(child, ci) in pageTree[item.id]"
        :key="'treeItem' + ci"
        :item="child"
        :pageTree="pageTree"
        @expand="onChildExpand"
      />
    </span>
  </div>
</template>

<script>
import { get } from "vuex-pathify";

/* global siteLangs */

export default {
  name: "nav-tree-item",

  props: {
    item: {
      type: Object,
      default: () => ({ id: 0, title: "Home" }),
    },

    pageTree: {
      type: Object,
      default: () => ({ 0: [] }),
    },
  },

  computed: {
    path: get("page/path"),
  },

  data: () => ({
    open: false,
  }),

  methods: {
    onClick() {
      if (this.item.isFolder) {
        this.open = !this.open;
      } else {
        window.location.assign(`/` + this.item.locale + `/` + this.item.path);
      }

      if (this.open) this.$emit("expand", this.item);
    },

    onChildExpand(item) {
      this.$emit("expand", item);
    },
  },

  mounted() {
    if (!this.item.isFolder || !this.pageTree[this.item.id]) return;

    const path = this.$store.get("page/path");

    const queue = [this.item];
    while (queue.length) {
      const item = queue.shift();
      if (item.path == path) {
        this.open = true;
        return;
      }

      if (item.isFolder && this.pageTree[item.id]) {
        queue.push(...this.pageTree[item.id]);
      }
    }
  },
};
</script>

<style lang="scss" scoped>
.sub-tree-item {
  display: flex;
  align-items: center;

  font-size: 0.9em;

  user-select: none;
  cursor: pointer;

  padding: 0.25em 0.5em;

  .v-icon {
    margin-right: 5px;
  }
}

.sub-tree-item.sub-tree-highlight {
  background-color: rgba(white, 0.2);
}

.sub-tree {
  display: flex;
  flex-flow: column;

  padding-left: 1em;
}
</style>