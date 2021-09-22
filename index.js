import React, {
  Component
} from 'react';
import PropTypes from 'prop-types';
import {
  NativeModules,
  DeviceEventEmitter,
  requireNativeComponent,
  View,
  Platform
} from 'react-native';
const WikitudeManager = NativeModules.RNWikitudeManager;
export default class Wikitude extends Component {
  static propTypes = {
    rendering: PropTypes.string,
    unload: PropTypes.string,
    licenseKey: PropTypes.string,
    architectWorldURL: PropTypes.string,
    onWikitudeEvent: PropTypes.func,
    ...View.propTypes,
  };
  static defaultProps = {
    rendering: "",
    unload: "",
    licenseKey:"",
    architectWorldURL:"",
    onWikitudeEvent:()=>{},
    style:null
  };
  constructor(props) {
    super(props);
    this.state = {
      rendering: "",
      unload: "",
      licenseKey:"",
      architectWorldURL:"",
      style:null
    };
    this._onWikitudeEvent = this._onWikitudeEvent.bind(this);
  }
  componentWillMount() {
    if (Platform.OS == 'android'){
      DeviceEventEmitter.addListener('onWikitudeEvent', this._onWikitudeEvent);
    }
  }
  componentDidMount() {
    // Because Android: SimpleViewManager doesn't seem compatible with @ReactMethod, so we're using a property in a
    // hokey manner to trigger rendering.
    this.setState({ rendering: 'start' });
  }
  componentWillUnmount(){
    this.close();
  }
  close() {
    if (Platform.OS === 'ios') {
      // For iOS: Using a property passed by state doesn't seem to move quick enough, so the unload property setter
      // doesn't seem to be called. Since methods do work over there, use that.
      WikitudeManager.unload();
    } else if (Platform.OS === 'android'){
      // For Android: SimpleViewManager doesn't seem compatible with @ReactMethod, so we're using a property in a hokey
      // manner to trigger unload.
      this.setState({ unload: 'unload' });
      DeviceEventEmitter.removeListener('onWikitudeEvent', this._onWikitudeEvent);
    }
  }
  _onWikitudeEvent(event) {
    if (!this.props.onWikitudeEvent) {
      return;
    }

    if (Platform.OS === 'ios') {
      event = event.nativeEvent;
    }
    this.props.onWikitudeEvent(event);
  }
  render() {
    let { architectWorldURL } = this.props;
    if (Platform.OS === 'android' && architectWorldURL[0] === '/') {
      architectWorldURL = 'file://' + architectWorldURL;
    }
    return (
      <View style={this.props.style} {...this.props}>
        <RNWikitude
          {...this.props}
          licenseKey={this.props.licenseKey}
          architectWorldURL={architectWorldURL}
          rendering={this.state.rendering}
          unload={this.state.unload}
          style={{flex: 1}}
          onWikitudeEvent={this._onWikitudeEvent}
        />
      </View>
    );
  }
}
const RNWikitude = requireNativeComponent('RNWikitude', Wikitude);
