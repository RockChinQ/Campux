<template>

  <BottomNavBar id="bnb" v-model="value" />

  <div id="container-wrap" style="height: calc(100vh - 64px)">

    <div id="pctabs">
      <h2 style="text-align: center; background-color: #42A5F5; color: #fff; padding: 8px 0px">Campux</h2>
      <div
        style="display: flex; justify-content: space-between; flex-direction: column; align-items: center; height: 100%">
        <div>
          <div id="pctab-btn" @click="$router.push('/');">
            <span>📝 投稿</span>
          </div>
          <div id="pctab-btn" @click="$router.push('/world');">
            <span style="font-weight: 1000">🌏 稿件</span>
          </div>
          <div id="pctab-btn" @click="$router.push('/service');">
            <span>🛠 服务</span>
          </div>
          <div id="pctab-btn" v-if="userGroup === 'admin' || userGroup === 'member'" @click="$router.push('/admin');">
            <span>🔐 管理</span>
          </div>
        </div>

        <div style="display: flex;">
          <img :src="avatarUrl" width="50" height="50" style="border-radius: 50%;">
          <div>
            <p style="margin-left: 16px; font-size: 16px; font-weight: bold;">{{ uin }}</p>
            <p style="margin-left: 16px; font-size: 12px; color: #666;">{{ userGroup }}</p>
          </div>
        </div>
      </div>


    </div>

    <!-- 纵向分割线 -->
    <div id="vdivider" style="height: calc(100vh - 64px); width: 1px; background-color: #f5f5f5;">
    </div>

    <div id="container">
      <div>
        <h2 id="mt" style="padding: 8px 16px; font-family: Lilita One; display: inline-block">Campux</h2>
        <span>{{ $store.state.metadata.brand }}</span>
      </div>
      <v-tabs id="tabs" v-model="tab" align-tabs="center" color="deep-purple-accent-4" show-arrows>
        <v-tab value="1">📰 你的稿件</v-tab>
        <v-tab value="2">🌏 动态</v-tab>
        <v-tab v-if="userGroup === 'admin' || userGroup === 'member'" value="3">🤵 审核稿件</v-tab>
      </v-tabs>

      <v-divider id="hdivider"></v-divider>

      <v-window v-model="tab" disabled>
        <v-window-item value="1">
          <div style="padding: 16px;">
            <!-- <v-select v-model="filter.status" label="按条件筛选" :items="filterStatus" variant="solo"
              @update:model-value="refreshPosts"></v-select> -->
            <div style="overflow-y: scroll; max-height: calc(100vh - 140px); min-height: calc(100vh - 140px);">
              <PostCard v-for="p in posts" :key="p.id" :post="p" typ="self" style="margin-top: 16px"
                @recall="recallPost" />
            </div>
          </div>
        </v-window-item>
        <v-window-item value="2">
          <div
            style="display: flex; justify-content: center; align-items: center; min-height: calc(100vh - 140px); margin-top: 32px;">
            <p style="font-weight: bold">前面的区域，以后再来探索吧</p>
          </div>
        </v-window-item>
        <v-window-item value="3">
          <div style="padding-inline: 16px;">
            <v-pagination :length="judgePages" v-model="judgeCurrentPage"
            @update:model-value="getJudgePosts"
            ></v-pagination>
            <!-- <v-select v-model="filterForJudge.status" label="按条件筛选" :items="filterStatus" variant="solo"
              @update:model-value="refreshPosts"></v-select> -->
            <div style="overflow-y: scroll; max-height: calc(100vh - 180px); min-height: calc(100vh - 200px);">
              <PostCard v-for="p in judgePosts" :key="p.id" :post="p" typ="judge" style="margin-top: 16px"
              currentFilterStatus="{{ filterForJudge.status }}"
                @updateJudgePost="updateJudgePost" />
            </div>
          </div>
        </v-window-item>
      </v-window>

      <v-snackbar v-model="snackbar.show" :color="snackbar.color" :timeout="snackbar.timeout"
        style="margin-bottom: 64px">
        {{ snackbar.text }}
      </v-snackbar>

    </div>
  </div>

  <v-menu>
    <template v-slot:activator="{ props }">
      <div style="position: fixed; right: 32px; bottom: 150px;">
        <v-btn v-bind="props" density="default" icon="mdi-filter" size="large" :loading="pullLoading" color="#42A5F5">
        </v-btn>
      </div>
    </template>
    <v-list @click:select="onFilterChange">
      <v-list-item v-for="(item, index) in filterStatus" :key="index" :value="index">
        <v-list-item-title>{{ item }}</v-list-item-title>
      </v-list-item>
    </v-list>
  </v-menu>

  <div style="position: fixed; right: 32px; bottom: 80px;">
    <v-btn density="default" icon="mdi-refresh" size="large" :loading="pullLoading" color="primary"
      @click="refreshPosts">
    </v-btn>
  </div>
</template>

<script>
import BottomNavBar from '@/components/BottomNavBar.vue'
import PostCard from '@/components/PostCard.vue'
export default {
  components: {
    BottomNavBar
  },
  data() {
    return {
      snackbar: {
        show: false,
        text: '',
        color: ''
      },
      value: 1,
      filter: {
        "status": "全部", // 状态
        "time_order": 1, // 时间排序
        "page": 1,
        "page_size": 9999
      },
      filterForJudge: {
        "uin": -1,
        "status": "待审核", // 状态
        "time_order": -1, // 时间排序
        "page": 1,
        "page_size": 10
      },
      posts: [],
      filterStatus: ['全部', '待审核', '已通过', '已拒绝', '已取消', '队列中', '已发布', '失败', '待撤回', '已撤回'],
      tab: null,
      uin: "",
      avatarUrl: "",
      userGroup: "user",
      judgePosts: [],
      judgePages: 1,
      judgeCurrentPage: 1,
      pullLoading: false,
    }
  },

  // watch tab
  watch: {
    tab: function (val) {
      if (val === '1') {
        this.getPosts()
      } else if (val === '3') {
        this.getJudgePosts()
      }
    }
  },

  mounted() {
    this.tokenLogin()
  },

  methods: {
    onFilterChange(e) {
      // console.log(e)
      let status = this.filterStatus[e.id]
      if (this.tab === '1') {
        this.filter.status = status
        this.getPosts()
      } else if (this.tab === '3') {
        this.filterForJudge.status = status
        this.getJudgePosts()
      }
    },
    updateJudgePost(p) {
      if (p.status === "通过") {
        p.status = 'approve'
      } else if (p.status === "拒绝") {
        p.status = 'reject'
        if (p.reason === "") {
          p.reason = "无理由"
        }
      } else if (p.status === "无理由拒绝") {
        p.status = 'reject'
        p.reason = "无理由"
      }

      let form = {
        "post_id": p.id,
        "option": p.status,
        "comment": p.reason
      }

      this.$axios.post('/v1/post/review-post', form)
        .then((response) => {
          if (response.data.code === 0) {
            this.toast('已经将该稿件' + p.status, 'success')
            this.refreshPosts()
          } else {
            this.toast('操作失败：' + response.data.msg)
          }
        })
        .catch((error) => {
          this.toast('操作失败：' + error.response.data.msg)
          console.error(error)
        })
    },
    refreshPosts() {
      if (this.tab === '1') {
        this.getPosts()
      } else if (this.tab === '3') {
        this.getJudgePosts()
      }
    },
    getJudgePosts() {
      console.log(this.filterForJudge)
      // 检查status
      let filter = JSON.parse(JSON.stringify(this.filterForJudge))
      for (let key in this.$store.state.statusMap) {
        if (this.$store.state.statusMap[key] === this.filterForJudge.status) {
          filter.status = key
          break
        }
      }

      filter.page = this.judgeCurrentPage

      this.pullLoading = true
      this.$axios.post('/v1/post/get-posts', filter)
        .then((response) => {
          if (response.data.code === 0) {
            let p = response.data.data.list
            if (p === null) {
              this.toast('无记录')
              this.judgePosts = []
              this.pullLoading = false
              return
            }
            for (let i = 0; i < p.length; i++) {
              // 2024-04-12T08:19:51.096Z 转成日期，再转成字符串
              let date = new Date(p[i].created_at)
              p[i].created_at = date.getUTCFullYear() + "-" + (date.getUTCMonth() + 1) + "-" + date.getUTCDate() + " " + date.getUTCHours() + ":" + date.getUTCMinutes() + ":" + date.getUTCSeconds()
              p[i].status = this.$store.state.statusMap[p[i].status]
              for (let j = 0; j < p[i].images.length; j++) {
                p[i].images[j] = this.$store.state.base_url + "/v1/post/download-image/" + p[i].images[j]
              }
            }
            console.log(p)
            this.judgePosts = p

            // 计算页数
            this.judgePages = Math.ceil(response.data.data.total / this.filterForJudge.page_size)
          } else {
            this.toast(response.data.msg)
          }
          this.pullLoading = false
          console.log(response.data)
        })
        .catch((error) => {
          this.pullLoading = false
          if (error.response.data.code === -1) {
            this.$router.push('/auth?hint=请先登录嗷')
            return
          }
          this.toast('获取稿件失败')
          console.log(error)
        })
    },
    tokenLogin() {
      this.$axios.get('/v1/account/token-check')
        .then(res => {
          if (res.data.code === 0) {
            this.uin = res.data.data.uin
            this.avatarUrl = "http://q1.qlogo.cn/g?b=qq&nk=" + res.data.data.uin + "&s=100"
            this.userGroup = res.data.data.user_group
          } else {
            this.toast('登录失败：' + res.data.msg)
          }
        })
        .catch(err => {
          if (err.response.data.code === -1) {
            this.$router.push('/auth?hint=请先登录嗷')
            return
          }
          this.toast('登录失败：' + err.response.data.msg)
          console.error(err)
        })
    },
    getPosts() {
      console.log(this.filter)
      // 检查status
      let filter = JSON.parse(JSON.stringify(this.filter))
      for (let key in this.$store.state.statusMap) {
        if (this.$store.state.statusMap[key] === this.filter.status) {
          filter.status = key
          break
        }
      }
      this.pullLoading = true
      this.$axios.post('/v1/post/get-self-posts', filter)
        .then((response) => {
          if (response.data.code === 0) {
            let p = response.data.data.list
            if (p === null) {
              this.toast('无记录')
              this.posts = []
              this.pullLoading = false
              return
            }
            // reverse
            p.reverse()
            for (let i = 0; i < p.length; i++) {
              // 2024-04-12T08:19:51.096Z 转成日期，再转成字符串，转成 YYYY-MM-DD HH:MM:SS UTC+8
              let date = new Date(p[i].created_at)
              p[i].created_at = date.getUTCFullYear() + "-" + (date.getUTCMonth() + 1) + "-" + date.getUTCDate() + " " + date.getUTCHours() + ":" + date.getUTCMinutes() + ":" + date.getUTCSeconds()
              p[i].status = this.$store.state.statusMap[p[i].status]
              for (let j = 0; j < p[i].images.length; j++) {
                p[i].images[j] = this.$store.state.base_url + "/v1/post/download-image/" + p[i].images[j]
              }
            }
            console.log(p)
            this.posts = p
          } else {
            this.toast(response.data.msg)
          }
          this.pullLoading = false
          console.log(response.data)
        })
        .catch((error) => {
          this.pullLoading = false
          this.toast(error)
          // if (error.response.data.code === -1) {
          //   this.$router.push('/auth?hint=请先登录嗷')
          //   return
          // }
          console.log(error)
        })
    },
    toast(text, color = 'error') {
      this.snackbar.text = text
      this.snackbar.color = color
      this.snackbar.show = true
    },
    recallPost(post) {
      console.log(post)
      this.$axios.post('/v1/post/user-cancel', {
        "post_id": post
      })
        .then((response) => {
          if (response.data.code === 0) {
            this.toast('取消成功', 'success')
            this.getPosts()
          } else {
            this.toast('取消失败：' + response.data.msg)
          }
        })
        .catch((error) => {
          this.toast('取消失败：' + error.response.data.msg)
          console.error(error)
        })
    },
  }
}
</script>

<style>
#container-wrap {
  min-height: 74vh;
}

/* 适配pc端 */
@media (min-width: 600px) {

  #mt {
    display: none;
  }


  #bnb {
    display: none;
  }

  #pctabs {
    display: block;
    min-width: 200px;
  }

  #container-wrap {
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
  }

  #container {
    height: 100%;
    margin-left: 16px;
    width: 60%;
  }

  #pctab-btn {
    padding: 12px 28px;
    margin-top: 16px;
    text-align: center;
    font-size: 18px;
    border-radius: 24px;
    cursor: pointer;
  }

  #pctab-btn:hover {
    background-color: #f5f5f5;
  }

  #vdivider {
    display: block;
  }
}

/* 适配移动端 */
@media (max-width: 600px) {
  #tabs {
    display: block;
  }

  #pctabs {
    display: none;
  }

  #vdivider {
    display: none;
  }
}
</style>